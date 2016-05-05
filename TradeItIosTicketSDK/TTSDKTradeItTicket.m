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
#import "TradeItMarketDataService.h"
#import "TradeItQuotesResult.h"
#import "TTSDKPortfolioService.h"

@interface TTSDKTradeItTicket() {
    TradeItTradeService * tradeService;

}

@property TTSDKUtils * utils;

@end

@implementation TTSDKTradeItTicket

static NSString * kBaseTabBarViewIdentifier = @"BASE_TAB_BAR";
static NSString * kAccountNavViewIdentifier = @"accountSelect";
static NSString * kAuthNavViewIdentifier = @"AUTH_NAV";
static NSString * kOnboardingNavViewIdentifier = @"ONBOARDING_NAV";
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


#pragma mark - Flow

-(void) prepareInitialFlow {
    self.loadingQuote = NO;

    // Immediately fire off a request for the publishers broker list
    if (!self.brokerList) {
        [self retrieveBrokers];
    }

    BOOL elapsed = NO;
    if (self.lastUsed) {
        if ((fabs([self.lastUsed timeIntervalSinceNow]) > 10)) {
            elapsed = YES;
        }
    }

    // If any sessions are in memory at this point, we know that we are simply reopening the ticket
    if ((!self.sessions || !self.sessions.count) || elapsed) {
        self.sessions = [[NSArray alloc] init];
        self.currentSession = nil;
        self.currentAccount = nil;
        self.previewRequest.accountNumber = @"";

        // Attempt to set an initial account
        NSString * lastSelectedAccountNumber = [self getLastSelected];
        NSArray * linkedAccounts = [TTSDKPortfolioService linkedAccounts];

        if (lastSelectedAccountNumber) {
            [self selectCurrentAccountByAccountNumber: lastSelectedAccountNumber];
        }

        if (!self.currentAccount && linkedAccounts.count) {
            [self selectCurrentAccount: [linkedAccounts lastObject]];
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

        if (self.currentSession) {
            [self retrieveQuote:^(void) {}];
        }

        [self authenticateSessionsInBackground];
    } else {
        [self retrieveQuote:^(void) {}];
    }

    self.lastUsed = [NSDate date];
}


#pragma mark - Flow: auth

-(void) launchAuthFlow {
    [self retrieveBrokers];

    [self presentAuthScreen];
}

-(void) presentAuthScreen {
    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];
    
    // If onboarding, use onboarding nav controller
    NSString * navIdentifier;
    if ([self.utils isOnboarding]) {
        navIdentifier = kOnboardingNavViewIdentifier;
    } else {
        navIdentifier = kAuthNavViewIdentifier;
    }

    UINavigationController * nav = (UINavigationController *)[ticket instantiateViewControllerWithIdentifier: navIdentifier];
    [nav setModalPresentationStyle:UIModalPresentationFullScreen];

    [self.parentView presentViewController:nav animated:YES completion:nil];
}


#pragma mark - Flow: accounts

-(void) launchAccountsFlow {
    // Immediately fire off a request for the publishers broker list
    [self prepareInitialFlow];

    [self presentAccountLinkScreen];
}

-(void) presentAccountLinkScreen {
    NSArray * linkedAccounts = [TTSDKPortfolioService linkedAccounts];

    if (linkedAccounts && linkedAccounts.count) {
        // Get storyboard
        UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];
        
        // Get account select navigation controller
        UINavigationController * accountSelectNav = (UINavigationController *)[ticket instantiateViewControllerWithIdentifier:@"ACCOUNT_LINK_NAV"];
        [accountSelectNav setModalPresentationStyle:UIModalPresentationFullScreen];
        
        [self configureAccountLinkNavController: accountSelectNav];

        [self.parentView presentViewController:accountSelectNav animated:YES completion:nil];
    } else {
        [self presentAuthScreen];
    }
}


#pragma mark - Flow: portfolio

-(void) launchPortfolioFlow {
    [self prepareInitialFlow];

    if (self.currentSession) {
        // Update ticket result
        self.resultContainer.status = USER_CANCELED;
        
        [self attemptTouchId:^(void) {
                [self performSelectorOnMainThread:@selector(presentPortfolioScreen) withObject:nil waitUntilDone:NO];
        } onFailure:^(void) {
                [self performSelectorOnMainThread:@selector(presentAuthScreen) withObject:nil waitUntilDone:NO];
        }];

    } else {
        // Update ticket result
        self.resultContainer.status = NO_BROKER;
        
        [self presentAuthScreen];
    }
}

-(void) presentPortfolioScreen {
    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];
    
    UINavigationController * nav = (UINavigationController *)[ticket instantiateViewControllerWithIdentifier: @"PortfolioController"];
    [nav setModalPresentationStyle:UIModalPresentationFullScreen];
    
    [self.parentView presentViewController:nav animated:YES completion:nil];
}


#pragma mark - Flow: trade

-(void) launchTradeFlow {
    [self prepareInitialFlow];

    if (self.currentSession) {
        // Update ticket result
        self.resultContainer.status = USER_CANCELED;

        [self attemptTouchId:^(void){
            [self performSelectorOnMainThread:@selector(presentTradeScreen) withObject:nil waitUntilDone:NO];
        } onFailure:^(void){
            [self performSelectorOnMainThread:@selector(presentAuthScreen) withObject:nil waitUntilDone:NO];
        }];

    } else {
        // Update ticket result
        self.resultContainer.status = NO_BROKER;
        
        [self presentAuthScreen];
    }
}

-(void) presentTradeScreen {
    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];

    UINavigationController * nav = (UINavigationController *)[ticket instantiateViewControllerWithIdentifier: @"TradeNavController"];
    [nav setModalPresentationStyle:UIModalPresentationFullScreen];
    
    [self.parentView presentViewController:nav animated:YES completion:nil];
}


#pragma mark - Flow: complete

- (void) launchTradeOrPortfolioFlow {
    [self prepareInitialFlow];

    if (self.currentSession) {
        // Update ticket result
        self.resultContainer.status = USER_CANCELED;

        [self attemptTouchId:^(void){
            [self performSelectorOnMainThread:@selector(presentTradeOrPortfolioScreen) withObject:nil waitUntilDone:NO];
        } onFailure:^(void){
            [self performSelectorOnMainThread:@selector(presentAuthScreen) withObject:nil waitUntilDone:NO];
        }];
        
    } else {
        // Update ticket result
        self.resultContainer.status = NO_BROKER;

        [self presentAuthScreen];
    }
}

-(void) presentTradeOrPortfolioScreen {
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


#pragma mark - Authentication

-(void) attemptTouchId:(void (^)(void)) successBlock onFailure:(void (^)(void)) failureBlock {
    // Before moving forward, authenticate through touch ID
    BOOL hasTouchId = [self isTouchIDAvailable];
    
#if TARGET_IPHONE_SIMULATOR
    hasTouchId = NO;
#endif
    
    if (hasTouchId) {
        [self promptTouchId:^(BOOL success) {
            if (success) {
                if (successBlock) {
                    successBlock();
                }
            } else {
                if (failureBlock) {
                    failureBlock();
                }
            }
        }];
    } else {
        if (successBlock) {
            successBlock();
        }
    }
}

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
        if (![session.login.userId isEqualToString:currentUserId] && !session.authenticating) {
            [session authenticateFromViewController:nil withCompletionBlock:nil];
        }
    }
}

-(BOOL) checkIsAuthenticationDuplicate:(NSArray *)accounts {
    NSDictionary * keyAccount = [accounts firstObject];

    BOOL isDuplicate = NO;

    NSArray * allAccounts = [TTSDKPortfolioService allAccounts];
    if (allAccounts && allAccounts.count) {
        for (NSDictionary * acct in allAccounts) {
            if ([keyAccount[@"accountNumber"] isEqualToString:acct[@"accountNumber"]]) {
                isDuplicate = YES;
            }
        }
    }
    
    return isDuplicate;
}


#pragma mark - Sessions

-(void) addSession:(TTSDKTicketSession *)session {
    NSMutableArray * newSessionList = [self.sessions mutableCopy];
    [newSessionList addObject: session];
    self.sessions = [newSessionList copy];
}

-(void) removeSession:(TTSDKTicketSession *)session {
    [self.connector unlinkLogin: session.login];

    NSMutableArray * newSessionList = [self.sessions mutableCopy];
    [newSessionList removeObject: session];
    self.sessions = [newSessionList copy];
}

-(void) selectCurrentSession:(TTSDKTicketSession *)session andAccount:(NSDictionary *)account {
    [self selectCurrentSession: session];
    [self selectCurrentAccount: account];
}

-(void) selectCurrentSession:(TTSDKTicketSession *)session {
    self.currentSession = session;
}


#pragma mark - Quotes

-(void) retrieveQuote:(void (^)(void))completionBlock {
    self.loadingQuote = YES;

    if (!self.quote.symbol) {
        self.loadingQuote = NO;
        return;
    }

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^{
        TradeItMarketDataService * quoteService = [[TradeItMarketDataService alloc] initWithSession: self.currentSession];

        TradeItQuotesRequest * quotesRequest = [[TradeItQuotesRequest alloc] initWithSymbol: self.quote.symbol];

        [quoteService getQuoteData:quotesRequest withCompletionBlock:^(TradeItResult * res){
            self.loadingQuote = NO;

            if ([res isKindOfClass:TradeItQuotesResult.class]) {
                TradeItQuotesResult * result = (TradeItQuotesResult *)res;
                TradeItQuote * resultQuote = [[TradeItQuote alloc] initWithQuoteData:(NSDictionary *)[result.quotes objectAtIndex:0]];
                self.quote = resultQuote;
            }

            if (completionBlock) {
                completionBlock();
            }
        }];
    });
}


#pragma mark - Accounts

-(void) replaceAccountsWithNewAccounts:(NSArray *)accounts {
    NSMutableArray * storedAccounts = [[TTSDKPortfolioService allAccounts] mutableCopy];

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
            sessionToRemove = session;
        }
    }

    [self removeSession: sessionToRemove];
    [self saveAccountsToUserDefaults: storedAccounts];
}

-(void) addAccounts:(NSArray *)accounts withSession:(TTSDKTicketSession *)session {
    NSArray * storedAccounts = [TTSDKPortfolioService allAccounts];

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

-(void) autoSelectAccount {

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
    
    NSArray * linkedAccounts = [TTSDKPortfolioService linkedAccounts];
    
    for (NSDictionary *account in linkedAccounts) {
        if ([accountNumber isEqualToString: [account valueForKey:@"accountNumber"]]) {
            self.currentAccount = account;
        }
    }
    
    [self setLastSelected: accountNumber];
    
    if (self.previewRequest) {
        self.previewRequest.accountNumber = accountNumber;
    }
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

-(void) configureAccountLinkNavController:(UINavigationController *)nav {
    // Set root to modal
    TTSDKAccountSelectViewController * root = (TTSDKAccountSelectViewController *)[nav.viewControllers objectAtIndex:0];
    
    // Set cancel button to close the app on completion
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(returnToParentApp)];
    root.navigationItem.rightBarButtonItem = cancelButton;
    root.navigationItem.hidesBackButton = NO;
}

-(void) removeBrokerSelectFromNav:(UINavigationController *)nav {
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];
    
    TTSDKLoginViewController * initialViewController = [ticket instantiateViewControllerWithIdentifier: @"LOGIN"];
    initialViewController.cancelToParent = YES;
    initialViewController.isModal = YES;
    
    [nav pushViewController:initialViewController animated:NO];
}

-(void) returnToParentApp {
    self.lastUsed = [NSDate date];

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
