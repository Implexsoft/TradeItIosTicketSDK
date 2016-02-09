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
#import "TradeItTradeService.h"

@interface TTSDKTicketController() {
    TradeItSession * session;
    TradeItTradeService * tradeService;
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

        [self launchInitialViewController];
    }];
}

-(void) launchInitialViewController {
    // Get storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];

    // Get logins
    NSArray * linkedLogins = [self.connector getLinkedLogins];

    // Has the user authenticated before?
    NSDictionary * initialAccount = [self attemptToRetrieveInitialAccount];
    BOOL authenticated = NO;
    if (initialAccount) {
        [self selectAccount:initialAccount];

        for (TradeItLinkedLogin * login in linkedLogins) {
            if (!login) {
                continue;
            }

            if ([login.userId isEqualToString:[initialAccount valueForKey:@"UserId"]]) {
                self.currentLogin = login;
                self.currentBroker = login.broker;
            }
        }

        if (self.currentLogin) {
            self.resultContainer.status = USER_CANCELED;
            authenticated = YES;
        }
    }

    // If user needs to authenticate, go either to onboarding or broker select
    if (!authenticated) {
        // The first item in the auth nav stack is the onboarding view
        UINavigationController * nav = (UINavigationController *)[ticket instantiateViewControllerWithIdentifier: kAuthNavViewIdentifier];
        [nav setModalPresentationStyle:UIModalPresentationFullScreen];

        // If not onboarding, push the nav to the broker select view
        if (![self isOnboarding]) {
            TTSDKBrokerSelectViewController * initialViewController = [ticket instantiateViewControllerWithIdentifier:kBrokerSelectViewIdentifier];
            [nav pushViewController:initialViewController animated:NO];
        }
        
        [self.parentView presentViewController:nav animated:YES completion:nil];
    } else {
        UITabBarController * tab = (UITabBarController *)[ticket instantiateViewControllerWithIdentifier: kBaseTabBarViewIdentifier];
        [tab setModalPresentationStyle:UIModalPresentationFullScreen];

        if (self.portfolioMode) {
            tab.selectedIndex = 1;
        } else {
            tab.selectedIndex = 0;
        }

        [self.parentView presentViewController:tab animated:YES completion:nil];
    }
}



#pragma mark - Authentication

-(void) authenticate:(TradeItAuthenticationInfo *)authInfo withCompletionBlock:(void (^)(TradeItResult *)) completionBlock {
    [self.connector linkBrokerWithAuthenticationInfo:authInfo andCompletionBlock:^(TradeItResult * res){
        if ([res isKindOfClass:TradeItErrorResult.class]) {
            completionBlock(res);
            return;
        }
        
        TradeItAuthLinkResult * result = (TradeItAuthLinkResult*)res;
        
        self.currentLogin = [self.connector saveLinkToKeychain:result withBroker:authInfo.broker];
        
        self.currentBroker = authInfo.broker;
        
        session = [[TradeItSession alloc] initWithConnector:self.connector];
        [session authenticate:self.currentLogin withCompletionBlock:completionBlock];
    }];
}

-(void) answerSecurityQuestion:(NSString *)answer withCompletionBlock:(void (^)(TradeItResult *)) completionBlock {
    [session answerSecurityQuestion:answer withCompletionBlock:completionBlock];
}

-(NSArray *) getLinkedLogins {
    return [self.connector getLinkedLogins];
}

-(NSArray *) retrieveStoredAccounts {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * storedAccounts = [defaults objectForKey:kAccountsKey];

    return storedAccounts;
}

-(NSDictionary *) attemptToRetrieveInitialAccount {
    NSDictionary * lastSelectedAccount;
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
        [acct setObject:self.currentLogin.userId forKey:@"UserId"];
        [acct setObject:[NSNumber numberWithBool:YES] forKey:@"active"];
        [acct setObject:[NSNumber numberWithBool:NO] forKey:@"lastSelected"];
        [newAccounts addObject:acct];
    }

    self.accounts = [storedAccounts arrayByAddingObjectsFromArray:newAccounts];

    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.accounts forKey:kAccountsKey];
    [defaults synchronize];
}

-(void) selectAccount:(NSDictionary *) account {
    self.currentAccount = account;
}

-(void) unlinkAccounts {
    
    NSArray * linkedLogins = [self.connector getLinkedLogins];
    
    int i;
    for (i = 0; i < linkedLogins.count; i++) {
        NSDictionary * login = [linkedLogins objectAtIndex:i];
        [self.connector unlinkBroker:[login valueForKey:@"broker"]];
    }
}



#pragma mark - Trading

-(void) createInitialTradeRequest {
    self.tradeRequest = [[TradeItPreviewTradeRequest alloc] init];

    [self.tradeRequest setOrderAction:@"buy"];

    if (self.position && self.position.symbol) {
        [self.tradeRequest setOrderSymbol: self.position.symbol];
    }

    [self.tradeRequest setOrderPriceType:@"market"];
}

-(void) createInitialTradeRequestWithSymbol:(NSString *)symbol andAction:(NSString *)action andQuantity:(NSNumber *)quantity {
    self.tradeRequest = [[TradeItPreviewTradeRequest alloc] init];

    if (action) {
        [self.tradeRequest setOrderAction: action];
    } else {
        [self.tradeRequest setOrderAction: @"buy"];
    }

    if (symbol) {
        [self.tradeRequest setOrderSymbol: symbol];
    }

    if (quantity) {
        [self.tradeRequest setOrderQuantity: quantity];
    } else {
        [self.tradeRequest setOrderQuantity: @1];
    }

    [self.tradeRequest setOrderPriceType: @"market"];
}

-(void) previewTrade:(void (^)(TradeItResult *)) completionBlock {
    [tradeService previewTrade:self.tradeRequest withCompletionBlock:^(TradeItResult * res){
        completionBlock(res);
    }];
}



#pragma mark - Positions and Balances

-(void) createInitialPositionWithSymbol:(NSString *)symbol andLastPrice:(NSNumber *)lastPrice {
    self.position = [[TradeItPosition alloc] init];

    [self.position setLastPrice:lastPrice];
    [self.position setSymbol:symbol];
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



#pragma mark - Navigation

-(void) returnToParentApp {
    [self.parentView dismissViewControllerAnimated:NO completion:^{
        if (self.callback) {
            self.callback(self.resultContainer);
        }
    }];
}



@end
