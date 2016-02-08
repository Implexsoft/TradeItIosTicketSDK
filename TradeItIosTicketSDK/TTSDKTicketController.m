//
//  TTSDKTicketController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/3/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKTicketController.h"
#import "TradeItConnector.h"
#import "TTSDKAccountSelectViewController.h"
#import "TTSDKTabBarViewController.h"
#import "TTSDKBrokerSelectViewController.h"
#import "TradeItErrorResult.h"
#import "TradeItSession.h"
#import "TradeItTradeService.h"

@interface TTSDKTicketController() {
    TradeItConnector * connector;
    TradeItSession * session;
    TradeItTradeService * tradeService;
}

@end

@implementation TTSDKTicketController

static NSString * kBrokerListKey = @"BROKER_LIST";
static NSString * kBrokerListViewIdentifier = @"BROKER_SELECT";
static NSString * kOnboardingViewIdentifier = @"ONBOARDING";
static NSString * kPortfolioViewIdentifier = @"PORTFOLIO";
static NSString * kTradeViewIdentifier = @"TRADE";
static NSString * kOnboardingKey = @"HAS_COMPLETED_ONBOARDING";


+ (id)globalController {
    static TTSDKTicketController * globalControllerInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalControllerInstance = [[self alloc] initWithApiKey:nil];
    });

    return globalControllerInstance;
}

- (id)initWithApiKey:(NSString *)apiKey {
    self = [super init];

    if (self) {
        self.apiKey = apiKey;
    }
    return self;
}

- (NSArray *)getDefaultBrokerList {
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


-(NSString *) getBrokerUsername:(NSString *) broker {
    NSDictionary *brokerUsernames = @{
                                      @"Dummy":@"Username",
                                      @"TD":@"User Id",
                                      @"Robinhood":@"Username",
                                      @"OptionsHouse":@"User Id",
                                      @"Schwabs":@"User Id",
                                      @"TradeStation":@"Username",
                                      @"Etrade":@"User Id",
                                      @"Fidelity":@"Username",
                                      @"Scottrade":@"Account #",
                                      @"Tradier":@"Username",
                                      @"IB":@"Username",
                                      };
    
    NSString * brokerName = [brokerUsernames valueForKey:broker];
    
    if (brokerName) {
        return brokerName;
    } else {
        return @"Username";
    }
}



- (BOOL)isOnboarding {
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

- (void)createInitialTradeRequest {
    self.tradeRequest = [[TradeItPreviewTradeRequest alloc] init];

    if (self.initialAction) {
        [self.tradeRequest setOrderAction:self.initialAction];
    }

    if (self.initialSymbol) {
        [self.tradeRequest setOrderSymbol:self.initialSymbol];
    }
}

- (void)showTicket {
    if (!connector) {
        connector = [[TradeItConnector alloc] initWithApiKey:self.apiKey];
    }

    //Get brokers
    [connector getAvailableBrokersWithCompletionBlock:^(NSArray * brokerList){
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

-(void)authenticate:(TradeItAuthenticationInfo *)authInfo withCompletionBlock:(void (^)(TradeItResult *)) completionBlock {
    [connector linkBrokerWithAuthenticationInfo:authInfo andCompletionBlock:^(TradeItResult * res){
        if ([res isKindOfClass:TradeItErrorResult.class]) {
            completionBlock(res);
            return;
        }

        TradeItAuthLinkResult * result = (TradeItAuthLinkResult*)res;

        self.currentLogin = [connector saveLinkToKeychain:result withBroker:authInfo.broker];

        self.currentBroker = authInfo.broker;

        session = [[TradeItSession alloc] initWithConnector:connector];
        [session authenticate:self.currentLogin withCompletionBlock:completionBlock];
    }];
}

-(void)answerSecurityQuestion:(NSString *)answer withCompletionBlock:(void (^)(TradeItResult *)) completionBlock {
    [session answerSecurityQuestion:answer withCompletionBlock:completionBlock];
}

-(void)launchInitialViewController {
    //Get Resource Bundle
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
    NSBundle * myBundle = [NSBundle bundleWithPath:bundlePath];
    NSString * startingView = kBrokerListViewIdentifier;
    NSArray * linkedLogins = [connector getLinkedLogins];

    if (linkedLogins.count > 0) {
        self.resultContainer.status = USER_CANCELED;
        startingView = self.portfolioMode ? kPortfolioViewIdentifier : kTradeViewIdentifier;
    }

    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: myBundle];
    UINavigationController * nav = (UINavigationController *)[ticket instantiateViewControllerWithIdentifier: @"AuthenticationNavController"];
    [nav setModalPresentationStyle:UIModalPresentationFullScreen];

    if (![self isOnboarding]) {
        TTSDKBrokerSelectViewController * initialViewController = [ticket instantiateViewControllerWithIdentifier:@"BROKER_SELECT"];
        [nav pushViewController:initialViewController animated:NO];
    }

    [self.parentView presentViewController:nav animated:YES completion:nil];
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

-(NSArray *) getLinkedLogins {
    return [connector getLinkedLogins];
}

-(void) unlinkAccounts {

    NSArray * linkedLogins = [connector getLinkedLogins];

    int i;
    for (i = 0; i < linkedLogins.count; i++) {
        NSDictionary * login = [linkedLogins objectAtIndex:i];
        [connector unlinkBroker:[login valueForKey:@"broker"]];
    }
}

-(void) returnToParentApp {
    [self.parentView dismissViewControllerAnimated:NO completion:^{
        if (self.callback) {
            self.callback(self.resultContainer);
        }
    }];
}





@end
