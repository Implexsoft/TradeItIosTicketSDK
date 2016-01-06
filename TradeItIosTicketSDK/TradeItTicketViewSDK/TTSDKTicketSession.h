//
//  TicketSession.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/13/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItStockOrEtfTradeSession.h"
#import "TradeItTicketControllerResult.h"
#import "TradeItAuthControllerResult.h"

@interface TTSDKTicketSession : TradeItStockOrEtfTradeSession

@property double lastPrice;
@property UIViewController * parentView;
@property NSString * errorTitle;
@property NSString * errorMessage;
@property (copy) void (^callback)(TradeItTicketControllerResult * result);
@property (copy) void (^refreshLastPrice)(NSString * symbol, void(^callback)(double lastPrice));
@property (copy) void (^refreshQuote)(NSString * symbol, void(^callback)(double lastPrice, double priceChangeDollar, double priceChangePercentage, NSString * quoteUpdateTime));
@property (copy) void (^brokerSignUpCallback)(TradeItAuthControllerResult * result);
@property NSString * companyName;
@property NSNumber * priceChangeDollar;
@property NSNumber * priceChangePercentage;
@property TradeItTicketControllerResult * resultContainer;
@property NSArray * brokerList;
@property BOOL brokerSignUpComplete;
@property BOOL debugMode;
@property BOOL portfolioMode;

@end
