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
#import "TTSDKPortfolioViewController.h"
#import "TTSDKPortfolioTableViewCell.h"
#import "TTSDKReviewScreenViewController.h"
#import "TTSDKSuccessViewController.h"
#import "TTSDKBrokerSelectViewController.h"
#import "TTSDKBrokerSelectDetailViewController.h"
#import "TTSDKBrokerSelectTableViewCell.h"


@implementation TradeItTicketController {
    TTSDKTicketSession * tradeSession;
}

+(void) showFullTicketWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol lastPrice:(double) lastPrice viewController:(UIViewController *) view {
    [TradeItTicketController showFullTicketWithPublisherApp:publisherApp symbol:symbol lastPrice:lastPrice orderAction:@"buy" viewController:view withDebug:NO onCompletion:nil];
}

+(void) showFullTicketWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol lastPrice:(double) lastPrice viewController:(UIViewController *) view onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {
    [TradeItTicketController showFullTicketWithPublisherApp:publisherApp symbol:symbol lastPrice:lastPrice orderAction:@"buy" viewController:view withDebug:NO onCompletion:callback];
}

+(void) debugShowFullTicketWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol lastPrice:(double) lastPrice viewController:(UIViewController *) view {
    [TradeItTicketController showFullTicketWithPublisherApp:publisherApp symbol:symbol lastPrice:lastPrice orderAction:@"buy" viewController:view withDebug:YES onCompletion:nil];
}


+(void) debugShowFullTicketWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol lastPrice:(double) lastPrice viewController:(UIViewController *) view onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {
    [TradeItTicketController showFullTicketWithPublisherApp:publisherApp symbol:symbol lastPrice:lastPrice orderAction:@"buy" viewController:view withDebug:YES onCompletion:callback];
}

+(void) showFullTicketWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol lastPrice:(double) lastPrice orderAction:(NSString *) action viewController:(UIViewController *) view {
        [TradeItTicketController showFullTicketWithPublisherApp:publisherApp symbol:symbol lastPrice:lastPrice orderAction:action viewController:view withDebug:NO onCompletion:nil];
}

+(void) showFullTicketWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol lastPrice:(double) lastPrice orderAction:(NSString *) action viewController:(UIViewController *) view onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {
            [TradeItTicketController showFullTicketWithPublisherApp:publisherApp symbol:symbol lastPrice:lastPrice orderAction:action viewController:view withDebug:NO onCompletion:callback];
}

+(void) showFullTicketWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol lastPrice:(double) lastPrice orderAction:(NSString *) action viewController:(UIViewController *) view withDebug:(BOOL) debug onCompletion:(void(^)(TradeItTicketControllerResult * result)) callback {

    [TradeItTicketController forceClassesIntoLinker];
    
    //Create Trade Session
    TTSDKTicketSession * tradeSession = [[TTSDKTicketSession alloc] initWithpublisherApp: publisherApp];
    tradeSession.orderInfo.symbol = [symbol uppercaseString];
    tradeSession.lastPrice = lastPrice;
    tradeSession.orderInfo.action = action;
    tradeSession.callback = callback;
    tradeSession.parentView = view;
    tradeSession.debugMode = debug;

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
    
    if(self.calcScreenDefault != nil && ![self.calcScreenDefault isEqualToString:@""]) {
        tradeSession.calcScreenStoryboardId = [self.calcScreenDefault isEqualToString:@"detail"] ? @"advCalculatorController" : @"initalCalculatorController";
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
    [TTSDKPortfolioViewController class];
    [TTSDKPortfolioTableViewCell class];
    [TTSDKReviewScreenViewController class];
    [TTSDKSuccessViewController class];
    [TTSDKBrokerSelectViewController class];
    [TTSDKBrokerSelectDetailViewController class];
    [TTSDKBrokerSelectTableViewCell class];
}
@end





















