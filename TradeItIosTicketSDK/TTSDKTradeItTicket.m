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
static NSString * kLastSelectedKey = @"TRADEIT_LAST_SELECTED";



#pragma mark - Initialization

+(id) globalTicket {
    static TTSDKTradeItTicket * globalTicketInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalTicketInstance = [[self alloc] init];
        globalTicketInstance.utils = [TTSDKUtils sharedUtils];
        globalTicketInstance.presentationMode = TradeItPresentationModeNone;
    });

    return globalTicketInstance;
}

-(void) prepareInitialFlow {
    // Immediately fire off a request for the publishers broker list
    [self retrieveBrokers];
    
    self.sessions = [[NSArray alloc] init];
    self.currentSession = nil;
    self.currentAccount = nil;
    self.previewRequest.accountNumber = @"";
    
    // Attempt to set an initial account
    NSString * lastSelectedAccountNumber = [self getLastSelected];
    
    if (lastSelectedAccountNumber) {
        [self selectCurrentAccountByAccountNumber: lastSelectedAccountNumber];
    } else if ([self.linkedAccounts count]) {
        [self selectCurrentAccount: [self.linkedAccounts lastObject]];
    }
    
    // Create a new, unauthenticated session for all stored logins
    NSArray * linkedLogins = [self.connector getLinkedLogins];
    for (TradeItLinkedLogin * login in linkedLogins) {
        TTSDKTicketSession * newSession = [[TTSDKTicketSession alloc] initWithConnector:self.connector andLinkedLogin:login andBroker: login.broker];
        [self addSession: newSession];
        
        // Attempt to set an initial session
        if (self.currentAccount && [login.userId isEqualToString:[self.currentAccount valueForKey: @"UserId"]]) {
            [self selectCurrentSession: newSession];
        }
    }
}

-(void) launchAuthFlow {
    // Immediately fire off a request for the publishers broker list
    [self retrieveBrokers];

    [self presentAuthScreen];
}

-(void) launchPortfolioFlow {
    [self prepareInitialFlow];

    if (self.currentSession) {
        // Update ticket result
        self.resultContainer.status = USER_CANCELED;
        
        // Before moving forward, authenticate through touch ID
        BOOL hasTouchId = [self isTouchIDAvailable];
        
#if TARGET_IPHONE_SIMULATOR
        hasTouchId = NO;
#endif
        
        if (hasTouchId) {
            [self promptTouchId:^(BOOL success) {
                if (success) {
                    [self performSelectorOnMainThread:@selector(presentPortfolioScreen) withObject:nil waitUntilDone:NO];
                } else {
                    [self performSelectorOnMainThread:@selector(presentAuthScreen) withObject:nil waitUntilDone:NO];
                }
            }];
        } else {
            [self presentPortfolioScreen];
        }

    } else {
        // Update ticket result
        self.resultContainer.status = NO_BROKER;
        
        [self presentAuthScreen];
    }
}

-(void) launchTradeFlow {
    [self prepareInitialFlow];

    if (self.currentSession) {
        // Update ticket result
        self.resultContainer.status = USER_CANCELED;
        
        // Before moving forward, authenticate through touch ID
        BOOL hasTouchId = [self isTouchIDAvailable];
        
#if TARGET_IPHONE_SIMULATOR
        hasTouchId = NO;
#endif
        
        if (hasTouchId) {
            [self promptTouchId:^(BOOL success) {
                if (success) {
                    [self performSelectorOnMainThread:@selector(presentTradeScreen) withObject:nil waitUntilDone:NO];
                } else {
                    [self performSelectorOnMainThread:@selector(presentAuthScreen) withObject:nil waitUntilDone:NO];
                }
            }];
        } else {
            [self presentTradeScreen];
        }
        
    } else {
        // Update ticket result
        self.resultContainer.status = NO_BROKER;
        
        [self presentAuthScreen];
    }
}

-(void) presentTradeScreen {
    [self authenticateSessionsInBackground];

    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];
    
    // The first item in the auth nav stack is the onboarding view
    UINavigationController * nav = (UINavigationController *)[ticket instantiateViewControllerWithIdentifier: @"TradeNavController"];
    [nav setModalPresentationStyle:UIModalPresentationFullScreen];
    
    [self.parentView presentViewController:nav animated:YES completion:nil];
}

-(void) presentPortfolioScreen {
    [self authenticateSessionsInBackground];

    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];
    
    // The first item in the auth nav stack is the onboarding view
    UINavigationController * nav = (UINavigationController *)[ticket instantiateViewControllerWithIdentifier: @"PortfolioController"];
    [nav setModalPresentationStyle:UIModalPresentationFullScreen];
    
    [self.parentView presentViewController:nav animated:YES completion:nil];
}

- (void) launchTradeOrPortfolioFlow {
    [self prepareInitialFlow];

    if (self.currentSession) {
        // Update ticket result
        self.resultContainer.status = USER_CANCELED;

        // Before moving forward, authenticate through touch ID
        BOOL hasTouchId = [self isTouchIDAvailable];

#if TARGET_IPHONE_SIMULATOR
        hasTouchId = NO;
#endif

        if (hasTouchId) {
            [self promptTouchId:^(BOOL success) {
                if (success) {
                    [self performSelectorOnMainThread:@selector(presentTradeOrPortfolioScreen) withObject:nil waitUntilDone:NO];
                } else {
                    [self performSelectorOnMainThread:@selector(presentAuthScreen) withObject:nil waitUntilDone:NO];
                }
            }];
        } else {
            [self presentTradeOrPortfolioScreen];
        }
        
    } else {
        // Update ticket result
        self.resultContainer.status = NO_BROKER;

        [self presentAuthScreen];
    }
}

-(void) presentAuthScreen {
    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];

    // The first item in the auth nav stack is the onboarding view
    UINavigationController * nav = (UINavigationController *)[ticket instantiateViewControllerWithIdentifier: kAuthNavViewIdentifier];
    [nav setModalPresentationStyle:UIModalPresentationFullScreen];

    // If not onboarding, push the nav to the broker select view
    if (![self.utils isOnboarding]) {
        [self removeOnboardingFromNav: nav];
    }

    [self.parentView presentViewController:nav animated:YES completion:nil];
}

-(void) presentTradeOrPortfolioScreen {
    [self authenticateSessionsInBackground];
    
    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];
    
    UITabBarController * tab = (UITabBarController *)[ticket instantiateViewControllerWithIdentifier: kBaseTabBarViewIdentifier];
    [tab setModalPresentationStyle:UIModalPresentationFullScreen];
    
    if (self.presentationMode == TradeItPresentationModePortfolio || self.presentationMode == TradeItPresentationModePortfolioOnly) {
        tab.selectedIndex = 1;
    } else {
        tab.selectedIndex = 0;
    }
    
    [self.parentView presentViewController:tab animated:YES completion:nil];
}

-(void) removeOnboardingFromNav:(UINavigationController *)nav {
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];

    TTSDKBrokerSelectViewController * initialViewController = [ticket instantiateViewControllerWithIdentifier: kBrokerSelectViewIdentifier];
    [nav pushViewController:initialViewController animated:NO];
}

-(void) removeBrokerSelectFromNav:(UINavigationController *)nav {
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];

    TTSDKLoginViewController * initialViewController = [ticket instantiateViewControllerWithIdentifier: @"LOGIN"];
    initialViewController.cancelToParent = YES;
    initialViewController.isModal = YES;

    [nav pushViewController:initialViewController animated:NO];
}

-(void) retrieveBrokers {
    [self.connector getAvailableBrokersWithCompletionBlock:^(NSArray * brokerList){
        if(brokerList == nil) {
            self.brokerList = [self getDefaultBrokerList];
        } else {
            NSMutableArray * brokers = [[NSMutableArray alloc] init];
            
            for (NSDictionary * broker in brokerList) {
                NSArray * entry = @[broker[@"longName"], broker[@"shortName"]];
                [brokers addObject:entry];
            }

            self.brokerList = brokers;
        }
    }];
}



#pragma mark - Authentication

- (BOOL) isTouchIDAvailable {
    if (![LAContext class]) {
        return NO;
    }

    LAContext *myContext = [[LAContext alloc] init];
    NSError *authError = nil;
    
    if (![myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
        return NO;
    }
    return YES;
}

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

-(void) removeSession:(TTSDKTicketSession *)session {
    NSMutableArray * newSessionList = [self.sessions mutableCopy];
    [newSessionList removeObject: session];
    self.sessions = [newSessionList copy];
}

-(BOOL) checkIsAuthenticationDuplicate:(NSArray *)accounts {
    NSDictionary * keyAccount = [accounts firstObject];

    BOOL isDuplicate = NO;

    if (self.allAccounts && self.allAccounts.count) {
        for (NSDictionary * acct in self.allAccounts) {
            if ([keyAccount[@"accountNumber"] isEqualToString:acct[@"accountNumber"]]) {
                isDuplicate = YES;
            }
        }
    }

    return isDuplicate;
}

-(void) selectCurrentSession:(TTSDKTicketSession *)session andAccount:(NSDictionary *)account {
    [self selectCurrentSession: session];
    [self selectCurrentAccount: account];
}

-(void) selectCurrentSession:(TTSDKTicketSession *)session {
    self.currentSession = session;
}



#pragma mark - Accounts

-(void) replaceAccountsWithNewAccounts:(NSArray *)accounts {
    NSMutableArray * storedAccounts = [self.allAccounts mutableCopy];

    __block NSString * oldSessionUserId = nil;

    if (!storedAccounts) {
        return;
    }

    for (NSDictionary *account in accounts) {
        [storedAccounts enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *acct, NSUInteger index, BOOL *stop) {
            if ([acct[@"accountNumber"] isEqualToString:account[@"accountNumber"]]) {
                oldSessionUserId = acct[@"userId"];
                [storedAccounts removeObjectAtIndex: index];
            }
        }];
    }

    TTSDKTicketSession * sessionToRemove = nil;

    for (TTSDKTicketSession *session in self.sessions) {
        if ([oldSessionUserId isEqualToString:session.login.userId]) {
            [self.connector unlinkLogin: session.login];
            sessionToRemove = session;
        }
    }

    [self removeSession: sessionToRemove];

    [self saveAccountsToUserDefaults: storedAccounts];
}

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

-(void) setLastSelected:(NSString *)accountNumber {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: accountNumber forKey:kLastSelectedKey];
    [defaults synchronize];
}

-(NSString *) getLastSelected {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * lastSelectedAccountNumber = [defaults objectForKey: kLastSelectedKey];

    return lastSelectedAccountNumber;
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
    NSString * userId = [account valueForKey: @"UserId"];

    TTSDKTicketSession * retrievedSession;

    for (TTSDKTicketSession *session in self.sessions) {
        if ([session.login.userId isEqualToString: userId]) {
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

-(void) selectCurrentAccount:(NSDictionary *)account {
    NSString * accountNumber = [account valueForKey:@"accountNumber"];

    [self selectCurrentAccountByAccountNumber: accountNumber];
}

-(void) selectCurrentAccountByAccountNumber:(NSString *)accountNumber {
    // Is same account as current?
    if ([accountNumber isEqualToString: [self.currentAccount valueForKey:@"accountNumber"]]) {
        return;
    }

    for (NSDictionary *account in self.linkedAccounts) {
        if ([accountNumber isEqualToString: [account valueForKey:@"accountNumber"]]) {
            self.currentAccount = account;
        }
    }

    [self setLastSelected: accountNumber];

    if (self.previewRequest) {
        self.previewRequest.accountNumber = accountNumber;
    }
}



#pragma mark - Navigation

-(void) returnToParentApp {
    self.presentationMode = TradeItPresentationModeNone;

    [self.parentView dismissViewControllerAnimated:NO completion:^{
        if (self.callback) {
            self.callback(self.resultContainer);
        }
    }];
}

-(void) restartTicket {
    [self.parentView dismissViewControllerAnimated:NO completion:nil];
    [self launchTradeOrPortfolioFlow];
}



@end
