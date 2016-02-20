//
//  ticket.m
//  TradeItTicketViewSDK
//
//  Created by Antonio Reyes on 7/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TradeItTicketController.h"
#import "TTSDKTradeItTicket.h"

#import "TTSDKTradeViewController.h"
#import "TTSDKCompanyDetails.h"
#import "TTSDKOrderTypeSelectionViewController.h"
#import "TTSDKOrderTypeInputViewController.h"
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
#import "TTSDKTabBarViewController.h"
#import "TTSDKUtils.h"
#import "TTSDKAccountLinkViewController.h"
#import "TTSDKAccountLinkTableViewCell.h"
#import "TradeItConnector.h"
#import "TTSDKPosition.h"
#import "TTSDKAccountService.h"
#import "TTSDKAccountSummaryResult.h"
#import "TTSDKSearchViewController.h"

@implementation TradeItTicketController {
    TTSDKUtils * utils;
}



+ (void)showPortfolioWithApiKey:(NSString *) apiKey viewController:(UIViewController *) view {
    [TradeItTicketController showPortfolioWithApiKey:apiKey viewController:view withDebug:NO onCompletion:nil];
}

+ (void)showPortfolioWithApiKey:(NSString *) apiKey viewController:(UIViewController *) view withDebug:(BOOL) debug onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {
    [TradeItTicketController forceClassesIntoLinker];

    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    [ticket setApiKey: apiKey];
    [ticket setCallback: callback];
    [ticket setParentView: view];
    [ticket setDebugMode: debug];
    [ticket setPortfolioMode: YES];

    [TradeItTicketController showTicket];
}

+ (void)showTicketWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol viewController:(UIViewController *) view {
    [TradeItTicketController showTicketWithApiKey:apiKey symbol:symbol orderAction:nil orderQuantity:nil viewController:view withDebug:NO onCompletion:nil];
}

+ (void)showTicketWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol orderAction:(NSString *) action orderQuantity:(NSNumber *)quantity viewController:(UIViewController *) view withDebug:(BOOL) debug onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {
    [TradeItTicketController forceClassesIntoLinker];

    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    [ticket setApiKey: apiKey];
    [ticket createInitialPreviewRequestWithSymbol:[symbol uppercaseString] andAction:action andQuantity:quantity];
    [ticket setCallback: callback];
    [ticket setParentView: view];
    [ticket setDebugMode: debug];
    [ticket setPortfolioMode: NO];

    [TradeItTicketController showTicket];
}

- (id)initWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol viewController:(UIViewController *) view {
    self = [super init];

    if (self) {
        TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

        [ticket setApiKey:apiKey];
        [ticket createInitialPreviewRequest]; // will set trade request to default values
        [ticket setParentView:view];
    }

    return self;
}

- (void)showTicket {
    utils = [TTSDKUtils sharedUtils];

    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    if(self.quantity > 0) {
        [ticket.initialPreviewRequest setOrderQuantity: [NSNumber numberWithInt: self.quantity]];
    }

    if(self.action != nil && ![self.action isEqualToString:@""]) {
        [ticket.initialPreviewRequest setOrderAction: self.action];
    }

    if (self.orderType != nil && ![self.orderType isEqualToString:@""]) {
        [ticket.initialPreviewRequest setOrderPriceType: self.orderType];
    }

    if(self.expiration != nil && ![self.expiration isEqualToString:@""]) {
        [ticket.initialPreviewRequest setOrderExpiration: self.expiration];
    }

    if(self.debugMode) {
        [ticket setDebugMode: YES];
    }

    if(self.onCompletion != nil) {
        [ticket setCallback: self.onCompletion];
    }

    if(self.refreshQuote) {
        [ticket setRefreshQuote: self.refreshQuote];
    } else if(self.refreshLastPrice != nil) {
        [ticket setRefreshLastPrice: self.refreshLastPrice];
    }

    if(self.companyName != nil && ![self.companyName isEqualToString:@""]) {
        [ticket setPositionCompanyName: self.companyName];
    }

    if(self.priceChangeDollar != nil) {
        [ticket.position setTotalGainLossDollar: self.priceChangeDollar];
    }

    if(self.priceChangePercentage != nil) {
        [ticket.position setTotalGainLossPercentage: self.priceChangePercentage];
    }

    [TradeItTicketController showTicket];
}

+(void) showTicket {
    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    [ticket setResultContainer: [[TradeItTicketControllerResult alloc] initNoBrokerStatus]];
    [ticket showTicket];
}

+ (void)clearSavedData {
    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    [ticket unlinkAccounts];
}

+ (NSArray *)getLinkedBrokers {
    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    return [ticket retrieveLinkedLogins];
}

+ (NSString *)getBrokerDisplayString:(NSString *) brokerIdentifier {
    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    return [ticket getBrokerDisplayString: brokerIdentifier];
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
    [TTSDKTabBarViewController class];
    [TTSDKAccountLinkViewController class];
    [TTSDKAccountLinkTableViewCell class];
    [TTSDKPosition class];
    [TTSDKAccountService class];
    [TTSDKAccountSummaryResult class];
    [TTSDKSearchViewController class];
}

@end





















