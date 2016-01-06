//
//  TicketController.m
//  TradeItTicketViewSDK
//
//  Created by Antonio Reyes on 7/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TradeItTicketController.h"
#import "TTSDKTicketSession.h"

#import "TTSDKOrderViewController.h"
#import "TTSDKAdvCalcTextField.h"
#import "TTSDKCompanyDetails.h"
#import "TTSDKOrderTypeSelectionViewController.h"
#import "TTSDKOrderTypeInputViewController.h"
#import "TTSDKSymbolSearchViewController.h"
#import "TTSDKAccountsViewController.h"
#import "TTSDKAccountsTableViewCell.h"
#import "TTSDKReviewScreenViewController.h"
#import "TTSDKSuccessViewController.h"
#import "TTSDKLinkPromptViewController.h"
#import "TTSDKBrokerSelectViewController.h"
#import "TTSDKBrokerSelectDetailViewController.h"
#import "TTSDKBrokerSelectTableViewCell.h"
#import "TTSDKPortfolioViewController.h"
#import "TTSDKAlertView.h"


@implementation TradeItTicketController {
    TTSDKTicketSession * tradeSession;
}


+(void) showPortfolioWithApiKey:(NSString *) apiKey viewController:(UIViewController *) view {
    [TradeItTicketController showPortfolioWithApiKey:apiKey viewController:view withDebug:NO onCompletion:nil];
}

+(void) showPortfolioWithApiKey:(NSString *) apiKey viewController:(UIViewController *) view withDebug:(BOOL) debug onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {
    [TradeItTicketController forceClassesIntoLinker];
    TTSDKTicketSession * tradeSession = [[TTSDKTicketSession alloc] initWithpublisherApp: apiKey];

    tradeSession.callback = callback;
    tradeSession.parentView = view;
    tradeSession.debugMode = debug;
    tradeSession.portfolioMode = YES;

    [TradeItTicketController showTicket:tradeSession];
}

+(void) showTicketWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol viewController:(UIViewController *) view {
    [TradeItTicketController showTicketWithApiKey:apiKey symbol:symbol lastPrice:0 orderAction:nil viewController:view withDebug:NO onCompletion:nil];
}

+(void) showTicketWithApiKey: (NSString *) apiKey symbol:(NSString *) symbol lastPrice:(double) lastPrice orderAction:(NSString *) action viewController:(UIViewController *) view withDebug:(BOOL) debug onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {
    [TradeItTicketController forceClassesIntoLinker];
    
    TTSDKTicketSession * tradeSession = [[TTSDKTicketSession alloc] initWithpublisherApp: apiKey];

    tradeSession.orderInfo.symbol = [symbol uppercaseString];
    tradeSession.lastPrice = lastPrice;
    tradeSession.orderInfo.action = action;
    tradeSession.callback = callback;
    tradeSession.parentView = view;
    tradeSession.debugMode = debug;
    tradeSession.portfolioMode = NO;

    [TradeItTicketController showTicket:tradeSession];
}

- (id) initWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol lastPrice:(double) lastPrice viewController:(UIViewController *) view {
    self = [super init];
    
    if (self) {
        tradeSession = [[TTSDKTicketSession alloc] initWithpublisherApp: publisherApp];
        tradeSession.orderInfo.symbol = [symbol uppercaseString];
        tradeSession.lastPrice = lastPrice;
        tradeSession.parentView = view;
    }
    
    return self;
}

-(void) showTicket {

    if(self.quantity > 0) {
        tradeSession.orderInfo.quantity = self.quantity;
    }
    
    if(self.action != nil && ![self.action isEqualToString:@""]) {
        tradeSession.orderInfo.action = self.action;
    }
    
    if([TTSDKTradeItTicket containsString:self.orderType searchString:@"stopLimit"]) {
        tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopLimit:0 :0];
    } else if([TTSDKTradeItTicket containsString:self.orderType searchString:@"stopMarket"]) {
        tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopMarket:0];
    } else if([TTSDKTradeItTicket containsString:self.orderType searchString:@"limit"]) {
        tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initLimit:0];
    }
    
    if(self.expiration != nil && ![self.expiration isEqualToString:@""]) {
        tradeSession.orderInfo.expiration = self.expiration;
    }
    
    if(self.debugMode) {
        tradeSession.debugMode = YES;
    }
    
    if(self.onCompletion != nil) {
        tradeSession.callback = self.onCompletion;
    }

    if(self.refreshQuote) {
        tradeSession.refreshQuote = self.refreshQuote;
    } else if(self.refreshLastPrice != nil) {
        tradeSession.refreshLastPrice = self.refreshLastPrice;
    }
    
    if(self.companyName != nil && ![self.companyName isEqualToString:@""]) {
        tradeSession.companyName = self.companyName;
    }
    
    if(self.priceChangeDollar != nil) {
        tradeSession.priceChangeDollar = self.priceChangeDollar;
    }
    
    if(self.priceChangePercentage != nil) {
        tradeSession.priceChangePercentage = self.priceChangePercentage;
    }

    [TradeItTicketController showTicket:tradeSession];
}

+(void) showTicket:(TTSDKTicketSession *) ticketSession {
    ticketSession.resultContainer = [[TradeItTicketControllerResult alloc] initNoBrokerStatus];

    [TTSDKTradeItTicket showTicket:ticketSession];
}

+(void) clearSavedData {
    NSArray * brokers = [TTSDKTradeItTicket getLinkedBrokersList];
    
    for (NSString * broker in brokers) {
        [TTSDKTradeItTicket removeLinkedBroker:broker];
        [TTSDKTradeItTicket storeUsername:@"" andPassword:@"" forBroker:broker];
    }
}

+(NSArray *) getLinkedBrokers {
    return [TTSDKTradeItTicket getLinkedBrokersList];
}

+(NSString *) getBrokerDisplayString:(NSString *) brokerIdentifier {
    return [TTSDKTradeItTicket getBrokerDisplayString:brokerIdentifier];
}

//Let me tell you a cool story about why this is here:
//Storyboards in bundles are static, non-compilled resources
//Therefore when the linker goes through the library it doesn't
//think any of the classes setup for the storyboard are in use
//so when we actually go to load up the storyboard, it explodes
//because all those classes aren't loaded into the app. So,
//we simply call a lame method on every view class which forces
//the linker to load the classes :)
+(void) forceClassesIntoLinker {
    [TTSDKOrderViewController class];
    [TTSDKAdvCalcTextField class];
    [TTSDKCompanyDetails class];
    [TTSDKOrderTypeSelectionViewController class];
    [TTSDKOrderTypeInputViewController class];
    [TTSDKSymbolSearchViewController class];
    [TTSDKAccountsViewController class];
    [TTSDKAccountsTableViewCell class];
    [TTSDKReviewScreenViewController class];
    [TTSDKSuccessViewController class];
    [TTSDKLinkPromptViewController class];
    [TTSDKBrokerSelectViewController class];
    [TTSDKBrokerSelectDetailViewController class];
    [TTSDKBrokerSelectTableViewCell class];
    [TTSDKPortfolioViewController class];
    [TTSDKAlertView class];
}
@end





















