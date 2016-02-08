//
//  TicketController.m
//  TradeItTicketViewSDK
//
//  Created by Antonio Reyes on 7/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TradeItTicketController.h"
#import "TTSDKTicketController.h"

#import "TTSDKTradeViewController.h"
#import "TTSDKCompanyDetails.h"
#import "TTSDKOrderTypeSelectionViewController.h"
#import "TTSDKOrderTypeInputViewController.h"
#import "TTSDKSymbolSearchViewController.h"
#import "TTSDKAccountSelectViewController.h"
#import "TTSDKAccountSelectTableViewCell.h"
#import "TTSDKReviewScreenViewController.h"
#import "TTSDKSuccessViewController.h"
#import "TTSDKOnboardingViewController.h"
#import "TTSDKBrokerSelectViewController.h"
#import "TTSDKLoginViewController.h"
#import "TTSDKBrokerSelectTableViewCell.h"
#import "TTSDKPortfolioViewController.h"
#import "TTSDKPortfolioHoldingTableViewCell.h"
#import "TTSDKPortfolioAccountsTableViewCell.h"
#import "TTSDKCustomAlertView.h"
#import "TTSDKTabBarViewController.h"
#import "TTSDKUtils.h"
#import "TTSDKAlertView.h"
#import "TTSDKAccountLinkViewController.h"
#import "TTSDKAccountLinkTableViewCell.h"
#import "TradeItConnector.h"


@implementation TradeItTicketController {
    TTSDKUtils * utils;
}


+ (void)showPortfolioWithApiKey:(NSString *) apiKey viewController:(UIViewController *) view {
    [TradeItTicketController showPortfolioWithApiKey:apiKey viewController:view withDebug:NO onCompletion:nil];
}

+ (void)showPortfolioWithApiKey:(NSString *) apiKey viewController:(UIViewController *) view withDebug:(BOOL) debug onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {
    [TradeItTicketController forceClassesIntoLinker];

    TTSDKTicketController * ticketController = [TTSDKTicketController globalController];
    ticketController.apiKey = apiKey;
    ticketController.callback = callback;
    ticketController.parentView = view;
    ticketController.debugMode = debug;
    ticketController.portfolioMode = YES;

    [self showTicket];
}

+ (void)showTicketWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol viewController:(UIViewController *) view {
    [TradeItTicketController showTicketWithApiKey:apiKey symbol:symbol lastPrice:0 orderAction:nil viewController:view withDebug:NO onCompletion:nil];
}

+ (void)showTicketWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol lastPrice:(double) lastPrice orderAction:(NSString *) action viewController:(UIViewController *) view withDebug:(BOOL) debug onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {
    [TradeItTicketController forceClassesIntoLinker];

    TTSDKTicketController * ticketController = [TTSDKTicketController globalController];
    ticketController.apiKey = apiKey;

    ticketController.tradeRequest = [[TradeItPreviewTradeRequest alloc] init];
    ticketController.tradeRequest.orderSymbol = [symbol uppercaseString];
    ticketController.tradeRequest.orderAction = action;

    ticketController.position = [[TradeItPosition alloc] init];
    ticketController.position.lastPrice = [NSNumber numberWithDouble:lastPrice];

    ticketController.callback = callback;
    ticketController.parentView = view;
    ticketController.debugMode = debug;
    ticketController.portfolioMode = NO;

    [self showTicket];
}

- (id)initWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol lastPrice:(double) lastPrice viewController:(UIViewController *) view {
    self = [super init];

    if (self) {
        TTSDKTicketController * controller = [TTSDKTicketController globalController];
        controller.apiKey = apiKey;
        controller.initialSymbol = [symbol uppercaseString];
        controller.initialLastPrice = lastPrice;
        controller.parentView = view;
        controller.tradeRequest = [[TradeItPreviewTradeRequest alloc] init];
        controller.position = [[TradeItPosition alloc] init];
    }

    return self;
}

- (void)showTicket {
    utils = [TTSDKUtils sharedUtils];

    TTSDKTicketController * controller = [TTSDKTicketController globalController];

    if(self.quantity > 0) {
        controller.tradeRequest.orderQuantity = [NSNumber numberWithInt:self.quantity];
    }

    if(self.action != nil && ![self.action isEqualToString:@""]) {
        controller.tradeRequest.orderAction = self.action;
    }

    if (self.orderType != nil && ![self.orderType isEqualToString:@""]) {
        controller.tradeRequest.orderPriceType = self.orderType;
    }

    if(self.expiration != nil && ![self.expiration isEqualToString:@""]) {
        controller.tradeRequest.orderExpiration = self.expiration;
    }

    if(self.debugMode) {
        controller.debugMode = YES;
    }

    if(self.onCompletion != nil) {
        controller.callback = self.onCompletion;
    }

    if(self.refreshQuote) {
        controller.refreshQuote = self.refreshQuote;
    } else if(self.refreshLastPrice != nil) {
        controller.refreshLastPrice = self.refreshLastPrice;
    }

    if(self.companyName != nil && ![self.companyName isEqualToString:@""]) {
        controller.positionCompanyName = self.companyName;
    }

    if(self.priceChangeDollar != nil) {
        controller.position.totalGainLossDollar = self.priceChangeDollar;
    }

    if(self.priceChangePercentage != nil) {
        controller.position.totalGainLossPercentage = self.priceChangePercentage;
    }

    [TradeItTicketController showTicket];
}

+(void) showTicket {
    TTSDKTicketController * controller = [TTSDKTicketController globalController];
    controller.resultContainer = [[TradeItTicketControllerResult alloc] initNoBrokerStatus];
    [controller showTicket];
}

+ (void)clearSavedData {
    TTSDKTicketController * ticketController = [TTSDKTicketController globalController];
    [ticketController unlinkAccounts];
}

+ (NSArray *)getLinkedBrokers {
    TTSDKTicketController * ticketController = [TTSDKTicketController globalController];
    return [ticketController getLinkedLogins];
}

+ (NSString *)getBrokerDisplayString:(NSString *) brokerIdentifier {
    TTSDKTicketController * ticketController = [TTSDKTicketController globalController];
    return [ticketController getBrokerDisplayString: brokerIdentifier];
}

//Let me tell you a cool story about why this is here:
//Storyboards in bundles are static, non-compilled resources
//Therefore when the linker goes through the library it doesn't
//think any of the classes setup for the storyboard are in use
//so when we actually go to load up the storyboard, it explodes
//because all those classes aren't loaded into the app. So,
//we simply call a lame method on every view class which forces
//the linker to load the classes :)
+ (void)forceClassesIntoLinker {
    [TTSDKTradeViewController class];
    [TTSDKCompanyDetails class];
    [TTSDKOrderTypeSelectionViewController class];
    [TTSDKOrderTypeInputViewController class];
    [TTSDKSymbolSearchViewController class];
    [TTSDKAccountSelectViewController class];
    [TTSDKAccountSelectTableViewCell class];
    [TTSDKReviewScreenViewController class];
    [TTSDKSuccessViewController class];
    [TTSDKOnboardingViewController class];
    [TTSDKBrokerSelectViewController class];
    [TTSDKLoginViewController class];
    [TTSDKBrokerSelectTableViewCell class];
    [TTSDKPortfolioViewController class];
    [TTSDKPortfolioHoldingTableViewCell class];
    [TTSDKPortfolioAccountsTableViewCell class];
    [TTSDKCustomAlertView class];
    [TTSDKTabBarViewController class];
    [TTSDKAccountLinkViewController class];
    [TTSDKAccountLinkTableViewCell class];

    [TTSDKAlertView class];
}
@end





















