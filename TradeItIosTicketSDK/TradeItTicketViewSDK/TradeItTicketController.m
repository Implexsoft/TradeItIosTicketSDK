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
#import "TTSDKPortfolioService.h"
#import "TTSDKAccountSummaryResult.h"
#import "TTSDKSearchViewController.h"
#import "TTSDKPortfolioAccount.h"
#import "TTSDKAccountsHeaderView.h"
#import "TTSDKHoldingsHeaderView.h"
#import "TTSDKLabel.h"
#import "TTSDKViewController.h"
#import "TTSDKTableViewController.h"
#import "TTSDKTextField.h"
#import "TTSDKPrimaryButton.h"
#import "TTSDKStyles.h"

@implementation TradeItTicketController {
    TTSDKUtils * utils;
    TTSDKStyles * styles;
}



#pragma mark - Class Initialization

+ (void)showPortfolioWithApiKey:(NSString *) apiKey viewController:(UIViewController *) view {
    [TradeItTicketController showPortfolioWithApiKey:apiKey viewController:view withDebug:NO onCompletion:nil];
}

+ (void)showPortfolioWithApiKey:(NSString *) apiKey viewController:(UIViewController *) view withDebug:(BOOL) debug onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {
    [TradeItTicketController forceClassesIntoLinker];

    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    ticket.callback = callback;
    ticket.parentView = view;
    ticket.debugMode = debug;
    ticket.portfolioMode = YES;
    ticket.connector = [[TradeItConnector alloc] initWithApiKey: apiKey];
    ticket.quote = [[TradeItQuote alloc] init];

    ticket.previewRequest = [[TradeItPreviewTradeRequest alloc] init];
    ticket.previewRequest.orderAction = @"buy";
    ticket.previewRequest.orderPriceType = @"market";
    ticket.previewRequest.orderQuantity = @1;

    [TradeItTicketController showTicket];
}

+ (void)showTicketWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol viewController:(UIViewController *) view {
    [TradeItTicketController showTicketWithApiKey:apiKey symbol:symbol orderAction:nil orderQuantity:nil viewController:view withDebug:NO onCompletion:nil];
}

+ (void)showTicketWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol orderAction:(NSString *) action orderQuantity:(NSNumber *)quantity viewController:(UIViewController *) view withDebug:(BOOL) debug onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {
    [TradeItTicketController forceClassesIntoLinker];

    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    ticket.connector = [[TradeItConnector alloc] initWithApiKey: apiKey];
    [ticket setCallback: callback];
    [ticket setParentView: view];
    [ticket setDebugMode: debug];
    [ticket setPortfolioMode: NO];

    ticket.quote = [[TradeItQuote alloc] init];
    ticket.quote.symbol = [symbol uppercaseString];

    ticket.previewRequest = [[TradeItPreviewTradeRequest alloc] init];
    ticket.previewRequest.orderSymbol = [symbol uppercaseString];
    ticket.previewRequest.orderAction = action;
    ticket.previewRequest.orderPriceType = @"market";
    ticket.previewRequest.orderQuantity = quantity;

    [TradeItTicketController showTicket];
}

+(void) showTicket {
    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];
    [ticket setResultContainer: [[TradeItTicketControllerResult alloc] initNoBrokerStatus]];

    if (ticket.authMode) {
        [ticket launchAuthFlow];
    } else {
        [ticket launchTradeOrPortfolioFlow];
    }
}

+ (void)clearSavedData {
    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    [ticket unlinkAccounts];
}

+ (NSArray *)getLinkedBrokers {
    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    return [ticket.connector getLinkedLogins];
}

+ (NSString *)getBrokerDisplayString:(NSString *) brokerIdentifier {
    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];
    
    return [ticket getBrokerDisplayString: brokerIdentifier];
}



#pragma mark - Instance Initialization

- (id)initWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol viewController:(UIViewController *) view {
    self = [super init];

    if (self) {
        TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];
        ticket.connector = [[TradeItConnector alloc] initWithApiKey: apiKey];
        self.symbol = symbol;
        [ticket setParentView:view];
        styles = [TTSDKStyles sharedStyles];
    }

    return self;
}

- (void)showTicket {
    utils = [TTSDKUtils sharedUtils];

    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];

    ticket.quote = [[TradeItQuote alloc] init];
    ticket.previewRequest = [[TradeItPreviewTradeRequest alloc] init];
    ticket.previewRequest.orderAction = @"buy";
    ticket.previewRequest.orderQuantity = @1;
    ticket.previewRequest.orderPriceType = @"market";

    if(self.quantity > 0) {
        [ticket.previewRequest setOrderQuantity: [NSNumber numberWithInt: self.quantity]];
    }

    if(self.action != nil && ![self.action isEqualToString:@""]) {
        [ticket.previewRequest setOrderAction: self.action];
    }

    if (self.orderType != nil && ![self.orderType isEqualToString:@""]) {
        [ticket.previewRequest setOrderPriceType: self.orderType];
    }

    if(self.expiration != nil && ![self.expiration isEqualToString:@""]) {
        [ticket.previewRequest setOrderExpiration: self.expiration];
    }

    if(self.debugMode) {
        [ticket setDebugMode: YES];
    }

    if(self.onCompletion != nil) {
        [ticket setCallback: self.onCompletion];
    }

    if (self.symbol != nil && ![self.symbol isEqualToString:@""]) {
        ticket.quote.symbol = [self.symbol uppercaseString];
        [ticket.previewRequest setOrderSymbol: [self.symbol uppercaseString]];
    }

    if(self.companyName != nil && ![self.companyName isEqualToString:@""]) {
        ticket.quote.companyName = self.companyName;
    }

    [TradeItTicketController showTicket];
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
    [TTSDKPortfolioService class];
    [TTSDKAccountSummaryResult class];
    [TTSDKSearchViewController class];
    [TTSDKPortfolioAccount class];
    [TTSDKAccountsHeaderView class];
    [TTSDKHoldingsHeaderView class];
    [TTSDKLabel class];
    [TTSDKTextField class];
    [TTSDKPrimaryButton class];
    [TTSDKViewController class];
    [TTSDKTableViewController class];
    [TTSDKStyles class];
}

@end





















