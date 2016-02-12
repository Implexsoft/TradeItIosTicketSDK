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

- (void) showTicket {
    if (!self.connector) {
        self.connector = [[TradeItConnector alloc] initWithApiKey:self.apiKey];
    }



    [self retrieveBrokers:^(void) {}];

    [self launchInitialViewController];
}

-(void) retrieveBrokers:(void (^)(void)) completionBlock {
    //Get brokers
    [self.connector getAvailableBrokersWithCompletionBlock:^(NSArray * brokerList){
        // set brokers
        if(brokerList == nil) {
            self.brokerList = [self getDefaultBrokerList];
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
            
            self.brokerList = (NSArray *) brokers;
        }

        completionBlock();
    }];
}

-(void) launchInitialViewController {
    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];

    // Get logins
    NSArray * linkedLogins = [self.connector getLinkedLogins];

    // Set up empty array of sessions
    NSMutableArray * sessions = [[NSMutableArray alloc] init];

    // First we need to see if the user has a (linked and active) account
    BOOL hasActiveAccount = NO;
    NSDictionary * initialAccount = [self attemptToRetrieveInitialAccount];

    if (linkedLogins.count) {
        for (TradeItLinkedLogin * login in linkedLogins) {
            TTSDKTicketSession * newSession = [[TTSDKTicketSession alloc] initWithConnector:self.connector andLinkedLogin:login andBroker: login.broker];

            [sessions addObject: newSession];

            if (initialAccount && [login.userId isEqualToString: [initialAccount valueForKey: @"UserId"]]) {
                [self.resultContainer setStatus: USER_CANCELED];
                self.currentSession = newSession;
                self.currentAccount = initialAccount;
                hasActiveAccount = YES;
            }
        }
    }

    // If user needs to link an account, go either to onboarding or broker select
    if (hasActiveAccount) {
        UITabBarController * tab = (UITabBarController *)[ticket instantiateViewControllerWithIdentifier: kBaseTabBarViewIdentifier];
        [tab setModalPresentationStyle:UIModalPresentationFullScreen];
        
        if (self.portfolioMode) {
            tab.selectedIndex = 1;
        } else {
            tab.selectedIndex = 0;
        }
        
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



#pragma mark - Authentication

-(NSArray *) getLinkedLogins {
    return [self.connector getLinkedLogins];
}

-(NSArray *) retrieveStoredAccounts {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * storedAccounts = [defaults objectForKey:kAccountsKey];

    return storedAccounts;
}

-(NSDictionary *) attemptToRetrieveInitialAccount {
    // Check to see which account was last selected by user
    NSDictionary * lastSelectedAccount;
    // If no last account is selected, then grab the last added active account
    NSDictionary * lastActiveAccount;

    NSArray * storedAccounts = [self retrieveStoredAccounts];
    if (storedAccounts && storedAccounts.count) {
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

    if (lastSelectedAccount) {
        return lastSelectedAccount;
    } else if (lastActiveAccount) {
        return lastActiveAccount;
    }

    return nil;
}

-(void) addAccounts:(NSArray *)accounts {
    NSArray * storedAccounts = [self retrieveStoredAccounts];

    if (!storedAccounts) {
        storedAccounts = [[NSArray alloc] init];
    }

    NSMutableArray * newAccounts = [[NSMutableArray alloc] init];
    int i;
    for (i = 0; i < accounts.count; i++) {
        NSMutableDictionary * acct = [NSMutableDictionary dictionaryWithDictionary:[accounts objectAtIndex:i]];
        [acct setObject:self.currentSession.login.userId forKey:@"UserId"];
        [acct setObject:[NSNumber numberWithBool:YES] forKey:@"active"];
        [acct setObject:[NSNumber numberWithBool:NO] forKey:@"lastSelected"];
        [acct setObject:self.currentSession.broker forKey:@"broker"];
        [newAccounts addObject:acct];
    }

    NSArray * appendedAccounts = [storedAccounts arrayByAddingObjectsFromArray:newAccounts];
    [self updateAccounts: appendedAccounts];
}

-(void) updateAccounts:(NSArray *)accounts {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: accounts forKey:kAccountsKey];
    [defaults synchronize];
}

-(void) appendSession:(TTSDKTicketSession *)session {
    if (!self.sessions) {
        self.sessions = [[NSArray alloc] init];
    }

    NSMutableArray * newSessionList = [self.sessions mutableCopy];
    [newSessionList addObject: session];
    self.sessions = [newSessionList copy];
    self.currentSession = session;
}

-(NSArray *) retrieveLinkedAccounts {
    NSMutableArray * linkedAccounts = [[NSMutableArray alloc] init];

    if (self.accounts.count) {
        int i;
        for (i = 0; i < self.accounts.count; i++) {
            NSDictionary * account = [self.accounts objectAtIndex:i];
            NSNumber * active = [account valueForKey: @"active"];

            if ([active boolValue]) {
                [linkedAccounts addObject: account];
            }
        }
    }

    return [linkedAccounts copy];
}

-(void) unlinkAccounts {
    NSArray * linkedLogins = [self.connector getLinkedLogins];

    int i;
    for (i = 0; i < linkedLogins.count; i++) {
        NSDictionary * login = [linkedLogins objectAtIndex:i];
        [self.connector unlinkBroker:[login valueForKey:@"broker"]];
    }
}

-(void) selectAccount:(NSDictionary *)account {
    NSMutableArray * storedAccounts = [NSMutableArray arrayWithArray: [self retrieveStoredAccounts]];
    
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
        
        self.currentAccount = selectedAccount;
    }
    
    [self updateAccounts: [storedAccounts copy]];
}

-(void) switchAccountsFromViewController:(UIViewController *)viewController toAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TradeItResult *)) completionBlock {

    self.accounts = [self retrieveStoredAccounts];
    
    if (self.currentSession.currentAccount && [account isEqualToDictionary:self.currentSession.currentAccount]) {
        return;
    }

    [self selectAccount: account];
    
    NSString * userId = [account valueForKey: @"UserId"];
    NSArray * linkedLogins = [self getLinkedLogins];
    TradeItLinkedLogin * newLogin;
    for (TradeItLinkedLogin * login in linkedLogins) {
        if ([login.userId isEqualToString: userId]) {
            newLogin = login;
            break;
        }
    }

    // See whether the new account exists under the current login. If not, change sessions
    if ([newLogin.userId isEqualToString:self.currentSession.login.userId]) {
        return;
    } else {
        [self switchSessionsFromViewController:viewController withLogin:newLogin];
    }
}

-(void) switchSessionsFromViewController:(UIViewController *)viewController withLogin:(TradeItLinkedLogin *)linkedLogin {
    TTSDKTicketSession * newSession;
    
    for (TTSDKTicketSession * session in self.sessions) {
        if ([session.login.userId isEqualToString:linkedLogin.userId]) {
            newSession = session;
            break;
        }
    }
    
    if (newSession) {
        self.currentSession = newSession;
    }
    
    if (!self.currentSession.isAuthenticated) {
        [self.currentSession authenticateFromViewController:viewController withCompletionBlock:^(TradeItResult * res) {
            // TODO
        }];
    }
}



#pragma mark - Trading

-(void) createInitialPreviewRequest {
    self.initialPreviewRequest = [[TradeItPreviewTradeRequest alloc] init];

    [self.initialPreviewRequest setOrderAction:@"buy"];

    if (self.position && self.position.symbol) {
        [self.initialPreviewRequest setOrderSymbol: self.position.symbol];
    }

    if (self.currentAccount) {
        [self.initialPreviewRequest setAccountNumber: [self.currentAccount valueForKey: @"accountNumber"]];
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

-(void) createInitialPositionWithSymbol:(NSString *)symbol andLastPrice:(NSNumber *)lastPrice {
    self.position = [[TradeItPosition alloc] init];

    [self.position setLastPrice: lastPrice];
    [self.position setSymbol: symbol];
}

-(void) retrievePositionsFromAccounts:(NSArray *)accounts withCompletionBlock:(void (^)(NSArray *)) completionBlock {
    NSArray * linkedLogins = [self getLinkedLogins];
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

-(void) checkPositionsCount {
    if ([positionsCounter isEqualToNumber: positionsTotal]) {
        [positionsTimer invalidate];
        positionsTimer = nil;
        positionsBlock(accountPositionsResult);
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
