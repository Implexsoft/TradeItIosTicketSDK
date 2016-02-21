//
//  TTSDKTicketController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/3/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKTradeItTicket.h"
#import "TTSDKUtils.h"
#import "TTSDKAccountSelectViewController.h"
#import "TTSDKTabBarViewController.h"
#import "TTSDKBrokerSelectViewController.h"
#import "TradeItErrorResult.h"
#import "TradeItSession.h"
#import "TradeItAuthenticationResult.h"
#import "TradeItTradeService.h"
#import "TradeItPositionService.h"
#import "TradeItGetPositionsRequest.h"
#import "TradeItBalanceService.h"
#import "TradeItAccountOverviewRequest.h"

@interface TTSDKTradeItTicket() {
    TradeItTradeService * tradeService;
}

@property TTSDKUtils * utils;

@end

@implementation TTSDKTradeItTicket

static NSString * kBaseTabBarViewIdentifier = @"BASE_TAB_BAR";
static NSString * kAuthNavViewIdentifier = @"AUTH_NAV";
static NSString * kBrokerSelectViewIdentifier = @"BROKER_SELECT";
static NSString * kOnboardingViewIdentifier = @"ONBOARDING";
static NSString * kPortfolioViewIdentifier = @"PORTFOLIO";
static NSString * kTradeViewIdentifier = @"TRADE";

static NSString * kAccountsKey = @"TRADEIT_ACCOUNTS";



#pragma mark - Getter and Setter Overrides

-(NSArray *)allAccounts {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * accounts = [defaults objectForKey:kAccountsKey];

    if (!accounts) {
        accounts = [[NSArray alloc] init];
    }
    
    return accounts;
}

-(NSArray *)linkedAccounts {
    NSMutableArray * linkedAccounts = [[NSMutableArray alloc] init];

    NSArray * storedAccounts = self.allAccounts;
    int i;
    for (i = 0; i < storedAccounts.count; i++) {
        NSDictionary * account = [storedAccounts objectAtIndex:i];
        NSNumber * active = [account valueForKey: @"active"];
        
        if ([active boolValue]) {
            [linkedAccounts addObject: account];
        }
    }

    return [linkedAccounts copy];
}

-(NSDictionary *)currentAccount {
    NSDictionary * currentAccount = nil;

    if (_currentSession) {
        currentAccount = _currentSession.currentAccount;
    }

    return currentAccount;
}

-(void)setCurrentAccount:(NSDictionary *)currentAccount {
    NSDictionary * selectedAccount;

    // Is same account as current?
    if (self.currentAccount){
        if ([currentAccount isEqualToDictionary: self.currentAccount]) {
            return;
        }
    }

    NSArray * linkedAccounts = self.linkedAccounts;
    for (NSDictionary * account in linkedAccounts) {
        if ([currentAccount isEqualToDictionary:account]) {
            selectedAccount = account;
        }
    }

    NSMutableDictionary * selectedAccountToAdd;
    NSDictionary * selectedAccountToRemove;
    NSMutableDictionary * deselectedAccountToAdd;
    NSDictionary * deselectedAccountToRemove;

    NSMutableArray * mutableAccounts = [self.allAccounts mutableCopy];
    for (NSDictionary * acct in mutableAccounts) {
        BOOL isLastSelected = [(NSNumber *)[acct valueForKey:@"lastSelected"] boolValue];

        if ([acct isEqualToDictionary: selectedAccount]) {
            selectedAccountToAdd = [acct mutableCopy];
            selectedAccountToRemove = acct;
        } else if (isLastSelected) {
            deselectedAccountToAdd = [acct mutableCopy];
            deselectedAccountToRemove = acct;
        }
    }

    if (deselectedAccountToAdd) {
        [deselectedAccountToAdd setValue:[NSNumber numberWithBool: NO] forKey: @"lastSelected"];
        [mutableAccounts removeObject: deselectedAccountToRemove];
        [mutableAccounts addObject: deselectedAccountToAdd];
    }

    if (selectedAccountToAdd) {
        [selectedAccount setValue:[NSNumber numberWithBool: YES] forKey:@"lastSelected"];
        [mutableAccounts removeObject: selectedAccountToRemove];
        [mutableAccounts addObject: selectedAccountToAdd];
    }

    [self saveAccountsToUserDefaults:[mutableAccounts copy]];

    // If account is not in current session, change session
    if (selectedAccount) {
        TTSDKTicketSession * selectedSession = [self retrieveSessionByAccount: selectedAccount];
        if (![selectedSession.login.userId isEqualToString:self.currentSession.login.userId]) {
            [self selectSession:selectedSession andAccount:currentAccount];
        }

        self.currentAccount = selectedAccount;
        self.previewRequest.accountNumber = [selectedAccount valueForKey:@"accountNumber"];
    }
}

-(void)setCurrentSession:(TTSDKTicketSession *)currentSession {
    if (_currentSession) {
        if ([currentSession.login.userId isEqualToString:_currentSession.login.userId]) {
            return;
        }
    }

    _currentSession.currentAccount = nil;
    _currentSession = currentSession;
}



#pragma mark - Initialization

+(id) globalTicket {
    static TTSDKTradeItTicket * globalTicketInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalTicketInstance = [[self alloc] init];
        globalTicketInstance.utils = [TTSDKUtils sharedUtils];
    });

    return globalTicketInstance;
}

- (void) showTicket {
    // Immediately fire off a request for the publishers broker list
    [self retrieveBrokers:^(NSArray * brokers) {
        self.brokerList = brokers;
    }];

    // Try to find an initial account
    NSArray * storedAccounts = self.allAccounts;
    NSDictionary * initialAccount;
    for (NSDictionary * account in storedAccounts) {
        NSNumber * isLastSelected = [account valueForKey:@"lastSelected"];
        NSNumber * isActive = [account valueForKey:@"active"];

        if ([isLastSelected boolValue] && [isActive boolValue]) {
            initialAccount = account;
            break;
        } else if ([isActive boolValue]) {
            initialAccount = account;
        }
    }
    
    // Create a new, unauthenticated session for all stored logins
    self.sessions = [[NSArray alloc] init];
    NSArray * linkedLogins = [self.connector getLinkedLogins];
    for (TradeItLinkedLogin * login in linkedLogins) {
        TTSDKTicketSession * newSession = [[TTSDKTicketSession alloc] initWithConnector:self.connector andLinkedLogin:login andBroker: login.broker];
        [self addSession: newSession];
        
        if (initialAccount && [login.userId isEqualToString: [initialAccount valueForKey: @"UserId"]]) {
            [self selectSession: newSession andAccount: initialAccount];
        }
    }

    if (self.currentSession) {
        // Update ticket result
        self.resultContainer.status = USER_CANCELED;

        // Before moving forward, authenticate through touch ID
        BOOL hasTouchId = !![LAContext class];

#if TARGET_IPHONE_SIMULATOR
        hasTouchId = NO;
#endif

        if (hasTouchId) {
            [self promptTouchId:^(BOOL success) {
                if (success) {
                    [self launchToTicket];
                } else {
                    [self launchToAuth];
                }
            }];
        } else {
            [self launchToTicket];
        }
        
    } else {
        // Update ticket result
        self.resultContainer.status = NO_BROKER;

        [self launchToAuth];
    }
}

-(void) launchToAuth {
    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];

    // The first item in the auth nav stack is the onboarding view
    UINavigationController * nav = (UINavigationController *)[ticket instantiateViewControllerWithIdentifier: kAuthNavViewIdentifier];
    [nav setModalPresentationStyle:UIModalPresentationFullScreen];

    // If not onboarding, push the nav to the broker select view
    if (![self.utils isOnboarding]) {
        TTSDKBrokerSelectViewController * initialViewController = [ticket instantiateViewControllerWithIdentifier: kBrokerSelectViewIdentifier];
        [nav pushViewController:initialViewController animated:NO];
    }

    [self.parentView presentViewController:nav animated:YES completion:nil];
}

-(void) launchToTicket {
    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];

    UITabBarController * tab = (UITabBarController *)[ticket instantiateViewControllerWithIdentifier: kBaseTabBarViewIdentifier];
    [tab setModalPresentationStyle:UIModalPresentationFullScreen];
    
    if (self.portfolioMode) {
        tab.selectedIndex = 1;
    } else {
        tab.selectedIndex = 0;
    }

    [self.parentView presentViewController:tab animated:YES completion:nil];
}

-(void) retrieveBrokers:(void (^)(NSArray *)) completionBlock {
    [self.connector getAvailableBrokersWithCompletionBlock:^(NSArray * brokerList){
        NSArray * brokersResult;
        if(brokerList == nil) {
            brokersResult = [self getDefaultBrokerList];
            completionBlock(brokersResult);
        } else {
            NSMutableArray * brokers = [[NSMutableArray alloc] init];
            
            for (NSDictionary * broker in brokerList) {
                NSArray * entry = @[broker[@"longName"], broker[@"shortName"]];
                [brokers addObject:entry];
            }
            
            brokersResult = [brokers copy];
            completionBlock(brokersResult);
        }
    }];
}



#pragma mark - Authentication

-(void) promptTouchId:(void (^)(BOOL)) completionBlock {
    LAContext * myContext = [[LAContext alloc] init];
    NSString * myLocalizedReasonString = @"Enable Broker Login to Continue";

    [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
              localizedReason:myLocalizedReasonString
                        reply:^(BOOL success, NSError *error) {
                            if (success) {
                                // TODO - set initial auth state
                                completionBlock(YES);
                            } else {
                                //too many tries, or cancelled by user
                                if(error.code == -2 || error.code == -1) {
                                    [self returnToParentApp];
                                } else if(error.code == -3) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if (completionBlock) {
                                            completionBlock(NO);
                                        }
                                    });
                                }
                            }
                        }];
}

-(void) authenticateSessionsInBackground {
    // For all sessions except current one, go ahead and authenticate for smoother user flows
    NSString * currentUserId = self.currentSession.login ? self.currentSession.login.userId : nil;
    
    for (TTSDKTicketSession * session in self.sessions) {
        if (![session.login.userId isEqualToString:currentUserId]) {
            [session authenticateFromViewController:nil withCompletionBlock:nil];
        }
    }
}

-(void) addSession:(TTSDKTicketSession *)session {
    NSMutableArray * newSessionList = [self.sessions mutableCopy];
    [newSessionList addObject: session];
    self.sessions = [newSessionList copy];
}

-(void) selectSession:(TTSDKTicketSession *)session andAccount:(NSDictionary *)account {
    self.currentSession = session;
    self.currentSession.currentAccount = account;
}



#pragma mark - Accounts

-(void) addAccounts:(NSArray *)accounts withSession:(TTSDKTicketSession *)session {
    NSArray * storedAccounts = self.allAccounts;

    NSMutableArray * newAccounts = [[NSMutableArray alloc] init];
    int i;
    for (i = 0; i < accounts.count; i++) {
        NSMutableDictionary * acct = [NSMutableDictionary dictionaryWithDictionary:[accounts objectAtIndex:i]];

        NSString * accountNumber = [acct valueForKey: @"accountNumber"];

        NSString * displayTitle = [NSString stringWithFormat:@"%@*%@",
                                   session.broker,
                                   [accountNumber substringFromIndex:accountNumber.length - 4]
                                   ];

        [acct setObject: session.login.userId forKey:@"UserId"];
        [acct setObject:[NSNumber numberWithBool:YES] forKey:@"active"];
        [acct setObject: displayTitle forKey:@"displayTitle"];
        [acct setObject:[NSNumber numberWithBool:NO] forKey:@"lastSelected"];
        [acct setObject: session.broker forKey:@"broker"];
        [newAccounts addObject:acct];
    }

    NSArray * appendedAccounts = [storedAccounts arrayByAddingObjectsFromArray:newAccounts];
    [self saveAccountsToUserDefaults: appendedAccounts];
}

-(void) saveAccountsToUserDefaults:(NSArray *)accounts {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: accounts forKey:kAccountsKey];
    [defaults synchronize];
}

-(void) unlinkAccounts {
    NSArray * linkedLogins = [self.connector getLinkedLogins];

    int i;
    for (i = 0; i < linkedLogins.count; i++) {
        NSDictionary * login = [linkedLogins objectAtIndex:i];
        [self.connector unlinkBroker:[login valueForKey:@"broker"]];
    }
}







#pragma mark - Positions and Balances

-(TTSDKTicketSession *) retrieveSessionByAccount:(NSDictionary *)account {
    NSString * accountNumber = [account valueForKey: @"UserId"];

    TTSDKTicketSession * retrievedSession;

    for (TTSDKTicketSession *session in self.sessions) {
        if ([session.login.userId isEqualToString: accountNumber]) {
            retrievedSession = session;
            break;
        }
    }

    return retrievedSession;
}



#pragma mark - Broker Utilities

-(NSArray *) getDefaultBrokerList {
    NSArray * brokers = @[
                          @[@"TD Ameritrade",@"TD"],
                          @[@"Robinhood",@"Robinhood"],
                          @[@"OptionsHouse",@"OptionsHouse"],
                          //@[@"Schwab",@"Schwabs"],
                          @[@"TradeStation",@"TradeStation"],
                          @[@"E*Trade",@"Etrade"],
                          @[@"Fidelity",@"Fidelity"],
                          @[@"Scottrade",@"Scottrade"],
                          @[@"Tradier Brokerage",@"Tradier"]
                          //@[@"Interactive Brokers",@"IB"]
                          ];
    
    return brokers;
}

-(NSString *) getBrokerDisplayString:(NSString *) value {
    NSArray * brokers = [self getDefaultBrokerList];

    for(NSArray * broker in brokers) {
        if([broker[1] isEqualToString:value]) {
            return broker[0];
        }
    }

    return value;
}

-(NSString *) getBrokerValueString:(NSString *) displayString {
    NSArray * brokers = [self getDefaultBrokerList];

    for(NSArray * broker in brokers) {
        if([broker[0] isEqualToString:displayString]) {
            return broker[1];
        }
    }

    return displayString;
}

-(NSArray *) getBrokerByValueString:(NSString *) valueString {
    NSArray * selectedBroker;

    for (NSArray * broker in self.brokerList) {
        if ([broker[1] isEqualToString:valueString]) {
            selectedBroker = broker;
            break;
        }
    }

    return selectedBroker;
}



#pragma mark - Navigation

-(void) returnToParentApp {
    [self.parentView dismissViewControllerAnimated:NO completion:^{
        if (self.callback) {
            self.callback(self.resultContainer);
        }
    }];
}

-(void) restartTicket {
    [self.parentView dismissViewControllerAnimated:NO completion:nil];
    [self showTicket];
}



@end
