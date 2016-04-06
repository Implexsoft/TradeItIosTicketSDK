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
#import "TTSDKViewController.h"

@implementation TradeItTicketController {
    TTSDKUtils * utils;
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
    [TradeItTicketController setAppearances];

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

    return [ticket.connector getLinkedLogins];
}

+ (NSString *)getBrokerDisplayString:(NSString *) brokerIdentifier {
    TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];
    
    return [ticket getBrokerDisplayString: brokerIdentifier];
}

+ (void)setAppearances {
    TTSDKUtils * utils = [TTSDKUtils sharedUtils];

    [[UINavigationBar appearanceWhenContainedIn:[TTSDKTabBarViewController class], nil] setBackgroundColor:nil];
    [[UITextField appearanceWhenContainedIn:[TTSDKTabBarViewController class], nil] setTextColor:nil];
    [[UIButton appearanceWhenContainedIn:[TTSDKTabBarViewController class], nil] setTitleColor:utils.activeButtonColor forState:UIControlStateNormal];
    [[UINavigationBar appearanceWhenContainedIn:[TTSDKTabBarViewController class], nil] setTintColor:nil];
    [[UIBarButtonItem appearanceWhenContainedIn:[TTSDKTabBarViewController class], nil] setTintColor:nil];

    [[UINavigationBar appearanceWhenContainedIn:[TTSDKPortfolioViewController class], nil] setBackgroundColor:nil];
    [[UITextField appearanceWhenContainedIn:[TTSDKPortfolioViewController class], nil] setTextColor:nil];
    [[UIButton appearanceWhenContainedIn:[TTSDKPortfolioViewController class], nil] setTitleColor:utils.activeButtonColor forState:UIControlStateNormal];
    [[UINavigationBar appearanceWhenContainedIn:[TTSDKPortfolioViewController class], nil] setTintColor:utils.activeButtonColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[TTSDKPortfolioViewController class], nil] setTintColor:utils.activeButtonColor];
    
    [[UINavigationBar appearanceWhenContainedIn:[TTSDKAccountSelectViewController class], nil] setBackgroundColor:nil];
    [[UITextField appearanceWhenContainedIn:[TTSDKAccountSelectViewController class], nil] setTextColor:nil];
    [[UIButton appearanceWhenContainedIn:[TTSDKAccountSelectViewController class], nil] setTitleColor:utils.activeButtonColor forState:UIControlStateNormal];
    [[UINavigationBar appearanceWhenContainedIn:[TTSDKAccountSelectViewController class], nil] setTintColor:utils.activeButtonColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[TTSDKAccountSelectViewController class], nil] setTintColor:utils.activeButtonColor];

    [[UINavigationBar appearanceWhenContainedIn:[TTSDKAccountLinkViewController class], nil] setBackgroundColor:nil];
    [[UITextField appearanceWhenContainedIn:[TTSDKAccountLinkViewController class], nil] setTextColor:nil];
    [[UIButton appearanceWhenContainedIn:[TTSDKAccountLinkViewController class], nil] setTitleColor:utils.activeButtonColor forState:UIControlStateNormal];
    [[UINavigationBar appearanceWhenContainedIn:[TTSDKAccountLinkViewController class], nil] setTintColor:utils.activeButtonColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[TTSDKAccountLinkViewController class], nil] setTintColor:utils.activeButtonColor];

    [[UINavigationBar appearanceWhenContainedIn:[TTSDKReviewScreenViewController class], nil] setBackgroundColor:nil];
    [[UITextField appearanceWhenContainedIn:[TTSDKReviewScreenViewController class], nil] setTextColor:nil];
    [[UIButton appearanceWhenContainedIn:[TTSDKReviewScreenViewController class], nil] setTitleColor:utils.activeButtonColor forState:UIControlStateNormal];
    [[UINavigationBar appearanceWhenContainedIn:[TTSDKReviewScreenViewController class], nil] setTintColor:utils.activeButtonColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[TTSDKReviewScreenViewController class], nil] setTintColor:utils.activeButtonColor];

    [[UINavigationBar appearanceWhenContainedIn:[TTSDKSuccessViewController class], nil] setBackgroundColor:nil];
    [[UITextField appearanceWhenContainedIn:[TTSDKSuccessViewController class], nil] setTextColor:nil];
    [[UIButton appearanceWhenContainedIn:[TTSDKSuccessViewController class], nil] setTitleColor:utils.activeButtonColor forState:UIControlStateNormal];
    [[UINavigationBar appearanceWhenContainedIn:[TTSDKSuccessViewController class], nil] setTintColor:utils.activeButtonColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[TTSDKSuccessViewController class], nil] setTintColor:utils.activeButtonColor];

    [[UINavigationBar appearanceWhenContainedIn:[TTSDKOnboardingViewController class], nil] setBackgroundColor:nil];
    [[UITextField appearanceWhenContainedIn:[TTSDKOnboardingViewController class], nil] setTextColor:nil];
    [[UIButton appearanceWhenContainedIn:[TTSDKOnboardingViewController class], nil] setTitleColor:utils.activeButtonColor forState:UIControlStateNormal];
    [[UINavigationBar appearanceWhenContainedIn:[TTSDKOnboardingViewController class], nil] setTintColor:utils.activeButtonColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[TTSDKOnboardingViewController class], nil] setTintColor:utils.activeButtonColor];

    [[UINavigationBar appearanceWhenContainedIn:[TTSDKLoginViewController class], nil] setBackgroundColor:nil];
    [[UITextField appearanceWhenContainedIn:[TTSDKLoginViewController class], nil] setTextColor:nil];
    [[UIButton appearanceWhenContainedIn:[TTSDKLoginViewController class], nil] setTitleColor:utils.activeButtonColor forState:UIControlStateNormal];
    [[UINavigationBar appearanceWhenContainedIn:[TTSDKLoginViewController class], nil] setTintColor:utils.activeButtonColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[TTSDKLoginViewController class], nil] setTintColor:utils.activeButtonColor];

    [[UINavigationBar appearanceWhenContainedIn:[TTSDKOrderTypeInputViewController class], nil] setBackgroundColor:nil];
    [[UITextField appearanceWhenContainedIn:[TTSDKOrderTypeInputViewController class], nil] setTextColor:nil];
    [[UIButton appearanceWhenContainedIn:[TTSDKOrderTypeInputViewController class], nil] setTitleColor:utils.activeButtonColor forState:UIControlStateNormal];
    [[UINavigationBar appearanceWhenContainedIn:[TTSDKOrderTypeInputViewController class], nil] setTintColor:utils.activeButtonColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[TTSDKOrderTypeInputViewController class], nil] setTintColor:utils.activeButtonColor];

    [[UINavigationBar appearanceWhenContainedIn:[TTSDKOrderTypeSelectionViewController class], nil] setBackgroundColor:nil];
    [[UITextField appearanceWhenContainedIn:[TTSDKOrderTypeSelectionViewController class], nil] setTextColor:utils.activeButtonColor];
    [[UIButton appearanceWhenContainedIn:[TTSDKOrderTypeSelectionViewController class], nil] setTitleColor:utils.activeButtonColor forState:UIControlStateNormal];
    [[UINavigationBar appearanceWhenContainedIn:[TTSDKOrderTypeSelectionViewController class], nil] setTintColor:utils.activeButtonColor];
    [[UIBarButtonItem appearanceWhenContainedIn:[TTSDKOrderTypeSelectionViewController class], nil] setTintColor:utils.activeButtonColor];
}



#pragma mark - Instance Initialization

- (id)initWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol viewController:(UIViewController *) view {
    self = [super init];

    if (self) {
        TTSDKTradeItTicket * ticket = [TTSDKTradeItTicket globalTicket];
        ticket.connector = [[TradeItConnector alloc] initWithApiKey: apiKey];
        self.symbol = symbol;
        [ticket setParentView:view];
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
    [TTSDKViewController class];
}

@end





















