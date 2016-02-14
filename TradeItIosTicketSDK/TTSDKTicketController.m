//
//  TTSDKTicketController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/3/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKTicketController.h"

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

typedef void(^PositionsCompletionBlock)(NSArray *);

@interface TTSDKTicketController() {
    TradeItTradeService * tradeService;

    NSNumber * positionsTotal;
    NSNumber * positionsCounter;
    NSTimer * positionsTimer;
    NSNumber * balancesTotal;
    NSNumber * balancesCounter;
    NSTimer * balancesTimer;
    PositionsCompletionBlock positionsBlock;
    NSMutableArray * accountPositionsResult;
}

@end

@implementation TTSDKTicketController

static NSString * kBaseTabBarViewIdentifier = @"BASE_TAB_BAR";
static NSString * kAuthNavViewIdentifier = @"AUTH_NAV";
static NSString * kBrokerSelectViewIdentifier = @"BROKER_SELECT";
static NSString * kOnboardingViewIdentifier = @"ONBOARDING";
static NSString * kPortfolioViewIdentifier = @"PORTFOLIO";
static NSString * kTradeViewIdentifier = @"TRADE";
static NSString * kOnboardingKey = @"HAS_COMPLETED_ONBOARDING";
static NSString * kAccountsKey = @"TRADEIT_ACCOUNTS";


+(id) globalController {
    static TTSDKTicketController * globalControllerInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalControllerInstance = [[self alloc] initWithApiKey:nil];
    });

    return globalControllerInstance;
}

-(id) initWithApiKey:(NSString *)apiKey {
    self = [super init];

    if (self) {
        self.apiKey = apiKey;
    }
    return self;
}



#pragma mark - Initialization

-(BOOL) isOnboarding {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSNumber * hasCompletedOnboarding = [defaults objectForKey:kOnboardingKey];

    BOOL complete = (BOOL)hasCompletedOnboarding;
    
    if (complete) {
        return NO;
    } else {
        [defaults setObject:@1 forKey:kOnboardingKey];
        return YES;
    }
}

-(void) retrieveBrokers:(void (^)(NSArray *)) completionBlock {
    //Get brokers

    [self.connector getAvailableBrokersWithCompletionBlock:^(NSArray * brokerList){
        // set brokers
        NSArray * brokersResult;
        if(brokerList == nil) {
            brokersResult = [self getDefaultBrokerList];
            completionBlock(brokersResult);
        } else {
            NSMutableArray * brokers = [[NSMutableArray alloc] init];

            if(self.debugMode) {
                NSArray * dummy  =  @[@"Dummy",@"Dummy"];
                [brokers addObject:dummy];
            }
            
            for (NSDictionary * broker in brokerList) {
                NSArray * entry = @[broker[@"longName"], broker[@"shortName"]];
                [brokers addObject:entry];
            }

            brokersResult = [brokers copy];
            completionBlock(brokersResult);
        }
    }];
}

- (void) showTicket {
    if (!self.connector) {
        self.connector = [[TradeItConnector alloc] initWithApiKey:self.apiKey];
        self.currentSession = [[TTSDKTicketSession alloc] initWithConnector: self.connector];
    }

    [self retrieveBrokers:^(NSArray * brokers) {
        self.brokerList = brokers;
    }];

    [self launchInitialViewController];
}

-(void) launchInitialViewController {
    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];

    // Try to set an initial login with associated session and account
    BOOL initialLoginFoundAndSet = [self attemptToSetInitialLogin];

    // If user needs to link an account, go either to onboarding or broker select
    if (initialLoginFoundAndSet) {
        [self passInitialPreviewRequestToSession];

        UITabBarController * tab = (UITabBarController *)[ticket instantiateViewControllerWithIdentifier: kBaseTabBarViewIdentifier];
        [tab setModalPresentationStyle:UIModalPresentationFullScreen];

        if (self.portfolioMode) {
            tab.selectedIndex = 1;
        } else {
            tab.selectedIndex = 0;
        }

        [self authenticateSessionsInBackground];

        [self.parentView presentViewController:tab animated:YES completion:nil];
    } else {
        // The first item in the auth nav stack is the onboarding view
        UINavigationController * nav = (UINavigationController *)[ticket instantiateViewControllerWithIdentifier: kAuthNavViewIdentifier];
        [nav setModalPresentationStyle:UIModalPresentationFullScreen];

        // If not onboarding, push the nav to the broker select view
        if (![self isOnboarding]) {
            TTSDKBrokerSelectViewController * initialViewController = [ticket instantiateViewControllerWithIdentifier: kBrokerSelectViewIdentifier];
            [nav pushViewController:initialViewController animated:NO];
        }

        [self.parentView presentViewController:nav animated:YES completion:nil];
    }
}

-(BOOL) attemptToSetInitialLogin {
    // Get stored logins
    NSArray * linkedLogins = [self.connector getLinkedLogins];

    // Get stored accounts
    NSArray * storedAccounts = [self retrieveAccounts];

    // Try to find an intitial account
    NSDictionary * lastSelectedAccount;
    NSDictionary * lastActiveAccount;
    NSDictionary * initialAccount;
    if ((linkedLogins && linkedLogins.count) && (storedAccounts && storedAccounts.count)) {
        for (NSDictionary * account in storedAccounts) {
            NSNumber * isLastSelected = [account valueForKey:@"lastSelected"];
            NSNumber * isActive = [account valueForKey:@"active"];
            
            if ([isLastSelected boolValue] && [isActive boolValue]) {
                lastSelectedAccount = account;
            } else if ([isActive boolValue]) {
                lastActiveAccount = account;
            }
        }
    }

    // Try to set the initial account to the last account selected by the user
    if (lastSelectedAccount) {
        initialAccount = lastSelectedAccount;

    // If that fails, just select the last (active) account that was added to the list
    } else if (lastActiveAccount) {
        initialAccount = lastActiveAccount;
    }

    BOOL initialLoginSet = NO;

    // If an initial account is found, match it with the appropriate linked login
    if (initialAccount) {
        for (TradeItLinkedLogin * login in linkedLogins) {
            // We want to create a new, unauthenticated session for each login we find, regardless
            TTSDKTicketSession * newSession = [[TTSDKTicketSession alloc] initWithConnector:self.connector andLinkedLogin:login andBroker: login.broker];
            [self addSession: newSession];

            if ([login.userId isEqualToString: [initialAccount valueForKey: @"UserId"]]) {
                [self.resultContainer setStatus: USER_CANCELED];
                [self selectSession: newSession andAccount: initialAccount];
                initialLoginSet = YES;
            }
        }
    }

    return initialLoginSet;
}



#pragma mark - Authentication

-(NSArray *) retrieveLinkedLogins {
    return [self.connector getLinkedLogins];
}

-(NSArray *) retrieveAccounts {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * accounts = [defaults objectForKey:kAccountsKey];

    return accounts;
}

-(NSArray *) retrieveLinkedAccounts {
    NSMutableArray * linkedAccounts = [[NSMutableArray alloc] init];
    NSArray * storedAccounts = [self retrieveAccounts];

    if (storedAccounts.count) {
        int i;
        for (i = 0; i < storedAccounts.count; i++) {
            NSDictionary * account = [storedAccounts objectAtIndex:i];
            NSNumber * active = [account valueForKey: @"active"];

            if ([active boolValue]) {
                [linkedAccounts addObject: account];
            }
        }
    }

    return [linkedAccounts copy];
}

-(void) addAccounts:(NSArray *)accounts withSession:(TTSDKTicketSession *)session {
    NSArray * storedAccounts = [self retrieveAccounts];

    if (!storedAccounts) {
        storedAccounts = [[NSArray alloc] init];
    }

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
    [self updateAccounts: appendedAccounts];
}

-(void) authenticateSessionsInBackground {
    // For all sessions that are not currently selected, go ahead and authenticate to smooth user flows
    NSString * currentUserId = self.currentSession.login ? self.currentSession.login.userId : nil;

    for (TTSDKTicketSession * session in self.sessions) {
        if (![session.login.userId isEqualToString:currentUserId]) {
            [session authenticateFromViewController:nil withCompletionBlock:nil];
        }
    }
}

-(void) updateAccounts:(NSArray *)accounts {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: accounts forKey:kAccountsKey];
    [defaults synchronize];
}

-(void) addSession:(TTSDKTicketSession *)session {
    if (!self.sessions) {
        self.sessions = [[NSArray alloc] init];
    }

    NSMutableArray * newSessionList = [self.sessions mutableCopy];
    [newSessionList addObject: session];
    self.sessions = [newSessionList copy];
}

-(void) unlinkAccounts {
    NSArray * linkedLogins = [self.connector getLinkedLogins];

    int i;
    for (i = 0; i < linkedLogins.count; i++) {
        NSDictionary * login = [linkedLogins objectAtIndex:i];
        [self.connector unlinkBroker:[login valueForKey:@"broker"]];
    }
}

-(void) switchAccountsFromViewController:(UIViewController *)viewController toAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TradeItResult *)) completionBlock {

    if (self.currentSession.currentAccount && [account isEqualToDictionary:self.currentSession.currentAccount]) {
        return;
    }

    NSString * userId = [account valueForKey: @"UserId"];
    NSArray * linkedLogins = [self retrieveLinkedLogins];
    TradeItLinkedLogin * newLogin;
    for (TradeItLinkedLogin * login in linkedLogins) {
        if ([login.userId isEqualToString: userId]) {
            newLogin = login;
            break;
        }
    }

    // See whether the new account exists under the current login. If not, change sessions
    if ([newLogin.userId isEqualToString: self.currentSession.login.userId]) {
        [self selectAccount: account];
        completionBlock(nil);
    } else {
        [self switchSessionsFromViewController:viewController withLogin:newLogin andAccount: account withCompletionBlock:completionBlock];
    }
}

-(void) selectAccount:(NSDictionary *)account {
    NSMutableArray * storedAccounts = [NSMutableArray arrayWithArray: [self retrieveAccounts]];
    
    NSMutableDictionary * selectedAccount;
    NSMutableDictionary * deselectedAccount;
    
    NSDictionary * selectedAccountToRemove;
    NSDictionary * deselectedAccountToRemove;
    
    for (NSDictionary * acct in storedAccounts) {
        BOOL isLastSelected = [(NSNumber *)[acct valueForKey:@"lastSelected"] boolValue];
        
        if ([acct isEqualToDictionary: account]) {
            selectedAccount = [acct mutableCopy];
            selectedAccountToRemove = acct;
        } else if (isLastSelected) {
            deselectedAccount = [acct mutableCopy];
            deselectedAccountToRemove = acct;
        }
    }
    
    if (deselectedAccount) {
        [deselectedAccount setValue:[NSNumber numberWithBool: NO] forKey: @"lastSelected"];
        
        [storedAccounts removeObject: deselectedAccountToRemove];
        [storedAccounts addObject: deselectedAccount];
    }
    
    if (selectedAccount) {
        [selectedAccount setValue:[NSNumber numberWithBool: YES] forKey:@"lastSelected"];
        
        [storedAccounts removeObject: selectedAccountToRemove];
        [storedAccounts addObject: selectedAccount];

        [self.currentSession setCurrentAccount: selectedAccount];
    }
    
    [self updateAccounts: [storedAccounts copy]];
}

-(void) switchSessionsFromViewController:(UIViewController *)viewController withLogin:(TradeItLinkedLogin *)linkedLogin andAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TradeItResult *)) completionBlock {
    TTSDKTicketSession * newSession;

    for (TTSDKTicketSession * session in self.sessions) {
        if ([session.login.userId isEqualToString:linkedLogin.userId]) {
            newSession = session;
            break;
        }
    }

    if (newSession) {
        [self selectSession: newSession andAccount: account];
    }

    if (!self.currentSession.isAuthenticated) {
        [self.currentSession authenticateFromViewController:viewController withCompletionBlock: completionBlock];
    } else {
        completionBlock(nil);
    }
}

-(void) selectSession:(TTSDKTicketSession *)session andAccount:(NSDictionary *)account {
    self.currentSession = session;
    [self.currentSession setCurrentAccount: account];
}



#pragma mark - Trading

-(void) createInitialPreviewRequest {
    self.initialPreviewRequest = [[TradeItPreviewTradeRequest alloc] init];

    [self.initialPreviewRequest setOrderAction:@"buy"];

    if (self.position && self.position.symbol) {
        [self.initialPreviewRequest setOrderSymbol: self.position.symbol];
    }

    if (self.currentSession.currentAccount) {
        [self.initialPreviewRequest setAccountNumber: [self.currentSession.currentAccount valueForKey: @"accountNumber"]];
    }

    [self.initialPreviewRequest setOrderPriceType:@"market"];
}

-(void) createInitialPreviewRequestWithSymbol:(NSString *)symbol andAction:(NSString *)action andQuantity:(NSNumber *)quantity {
    self.initialPreviewRequest = [[TradeItPreviewTradeRequest alloc] init];

    if (action) {
        [self.initialPreviewRequest setOrderAction: action];
    } else {
        [self.initialPreviewRequest setOrderAction: @"buy"];
    }

    if (symbol) {
        [self.initialPreviewRequest setOrderSymbol: symbol];
    }

    if (quantity) {
        [self.initialPreviewRequest setOrderQuantity: quantity];
    } else {
        [self.initialPreviewRequest setOrderQuantity: @1];
    }

    [self.initialPreviewRequest setOrderPriceType: @"market"];
}

-(void) passInitialPreviewRequestToSession {
    if (self.currentSession && self.initialPreviewRequest != nil) {
        self.currentSession.previewRequest = self.initialPreviewRequest;
        self.initialPreviewRequest = nil;
    }
}

//
//-(void) previewTrade:(void (^)(TradeItResult *)) completionBlock {
//    tradeService = [[TradeItTradeService alloc] initWithSession: session];
//
//    [tradeService previewTrade:self.tradeRequest withCompletionBlock:^(TradeItResult * res){
//        completionBlock(res);
//    }];
//}
//
//-(void) placeTrade:(void (^)(TradeItResult *)) completionBlock {
//    [tradeService placeTrade: self.placeTradeRequest withCompletionBlock: completionBlock];
//}



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

-(void) createInitialPositionWithSymbol:(NSString *)symbol andLastPrice:(NSNumber *)lastPrice {
    self.position = [[TradeItPosition alloc] init];

    [self.position setLastPrice: lastPrice];
    [self.position setSymbol: symbol];
}

-(void) retrievePortfolioDataFromAllAccounts:(void (^)(NSArray *)) completionBlock {
    NSArray * totalAccounts = [self retrieveAccounts];

    NSMutableArray * totalPositions = [[NSMutableArray alloc] init];
//    NSMutableArray * balances = [[NSMutableArray alloc] init];

    positionsBlock = completionBlock;
    accountPositionsResult = [[NSMutableArray alloc] init];
    positionsTotal = [NSNumber numberWithInteger: totalAccounts.count];
    positionsCounter = @0;
    positionsTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkPositionsCount) userInfo:totalPositions repeats:YES];

    for (NSDictionary * account in totalAccounts) {
        TTSDKTicketSession * session = [self retrieveSessionByAccount: account];

        NSLog(@"GETTING POSITIONS FROM ACCOUNT");

        [session getPositionsFromAccount: account withCompletionBlock:^(NSArray * positions) {
            positionsCounter = [NSNumber numberWithInt: [positionsCounter intValue] + 1 ];
            [accountPositionsResult addObjectsFromArray: positions];
        }];
    }
}

-(void) checkPositionsCount {
    if ([positionsCounter isEqualToNumber: positionsTotal]) {
        [positionsTimer invalidate];
        positionsTimer = nil;
        positionsBlock([accountPositionsResult copy]);
    }
}

-(void) retrievePositionsFromAccounts:(NSArray *)accounts withCompletionBlock:(void (^)(NSArray *)) completionBlock {
    NSArray * linkedLogins = [self retrieveLinkedLogins];
    NSMutableArray * positions = [[NSMutableArray alloc] init];

    positionsBlock = completionBlock;
    accountPositionsResult = [[NSMutableArray alloc] init];

    positionsTotal = [NSNumber numberWithInteger: accounts.count];
    positionsCounter = @0;
    positionsTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkPositionsCount) userInfo:positions repeats:YES];

    int i;
    for (i = 0; i < accounts.count; i++) {
        NSDictionary * account = (NSDictionary *)[accounts objectAtIndex: i];
        TradeItLinkedLogin * selectedLogin;

        for (TradeItLinkedLogin * login in linkedLogins) {
            if ([login.userId isEqualToString: [account valueForKey:@"UserId"]]) {
                selectedLogin = login;
                break;
            }
        }

        TradeItSession * tempSession = [[TradeItSession alloc] initWithConnector:self.connector];
        [tempSession authenticate:selectedLogin withCompletionBlock:^(TradeItResult * result) {
            if ([result isKindOfClass: TradeItErrorResult.class]) {
                return;
            } else {
                TradeItGetPositionsRequest * tempRequest = [[TradeItGetPositionsRequest alloc] initWithAccountNumber: [account valueForKey: @"accountNumber"]];

                TradeItPositionService * positionService = [[TradeItPositionService alloc] initWithSession: tempSession];
                [positionService getAccountPositions: tempRequest  withCompletionBlock:^(TradeItResult * result) {
                    if ([result isKindOfClass: TradeItGetPositionsResult.class]) {
                        TradeItGetPositionsResult * positionsResult = (TradeItGetPositionsResult *)result;
                        positionsCounter = [NSNumber numberWithInt: [positionsCounter intValue] + 1 ];
                        [accountPositionsResult addObjectsFromArray: positionsResult.positions];

                        [positions addObject:positionsResult.positions];
                    }
                }];
            }
        }];
    }
}

-(void) retrieveAccountOverview:(NSString *)accountNumber withCompletionBlock:(void (^)(TradeItResult *)) completionBlock {
    if (!self.currentSession.isAuthenticated) {
        [self.currentSession authenticate:self.currentSession.login withCompletionBlock:^(TradeItResult * res) {
            TradeItBalanceService * balanceService = [[TradeItBalanceService alloc] initWithSession: self.currentSession];
            TradeItAccountOverviewRequest * request = [[TradeItAccountOverviewRequest alloc] initWithAccountNumber: accountNumber];
            [balanceService getAccountOverview:request withCompletionBlock:^(TradeItResult * result) {
                if ([result isKindOfClass:TradeItAccountOverviewResult.class]) {
                    self.currentAccountOverview = (TradeItAccountOverviewResult *)result;
                }
                completionBlock(result);
            }];
        }];
    } else {
        TradeItBalanceService * balanceService = [[TradeItBalanceService alloc] initWithSession: self.currentSession];
        TradeItAccountOverviewRequest * request = [[TradeItAccountOverviewRequest alloc] initWithAccountNumber: accountNumber];
        [balanceService getAccountOverview:request withCompletionBlock:^(TradeItResult * result) {
            if ([result isKindOfClass:TradeItAccountOverviewResult.class]) {
                self.currentAccountOverview = (TradeItAccountOverviewResult *)result;
            }
            completionBlock(result);
        }];
    }
}

-(void) retrievePositionsFromAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TradeItResult *)) completionBlock {
    if (!self.currentSession.isAuthenticated) {
        [self.currentSession authenticate:self.currentSession.login withCompletionBlock:^(TradeItResult * res) {
            TradeItPositionService * positionService = [[TradeItPositionService alloc] initWithSession: self.currentSession];
            TradeItGetPositionsRequest * request = [[TradeItGetPositionsRequest alloc] initWithAccountNumber:[account valueForKey:@"accountNumber"]];

            [positionService getAccountPositions: request withCompletionBlock:^(TradeItResult * result) {
                if ([result isKindOfClass:TradeItGetPositionsResult.class]) {
                    self.currentPositionsResult = (TradeItGetPositionsResult *)result;
                }
                completionBlock(result);
            }];
        }];
    } else {
        TradeItPositionService * positionService = [[TradeItPositionService alloc] initWithSession: self.currentSession];
        TradeItGetPositionsRequest * request = [[TradeItGetPositionsRequest alloc] initWithAccountNumber:[account valueForKey:@"accountNumber"]];

        [positionService getAccountPositions: request withCompletionBlock:^(TradeItResult * result) {
            if ([result isKindOfClass:TradeItGetPositionsResult.class]) {
                self.currentPositionsResult = (TradeItGetPositionsResult *)result;
            }
            completionBlock(result);
        }];
    }
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
