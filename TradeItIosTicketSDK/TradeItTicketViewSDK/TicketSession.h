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

@interface TicketSession : TradeItStockOrEtfTradeSession

@property BOOL debugMode;

@property double lastPrice;

@property UIViewController * parentView;
@property BOOL popToRoot;

@property NSString * errorTitle;
@property NSString * errorMessage;

@property (copy) void (^callback)(TradeItTicketControllerResult * result);
@property (copy) void (^refreshLastPrice)(NSString * symbol, void(^callback)(double lastPrice));
@property (copy) void (^refreshQuote)(NSString * symbol, void(^callback)(double lastPrice, double priceChangeDollar, double priceChangePercentage, NSString * quoteUpdateTime));

@property NSString * calcScreenStoryboardId;

@property NSString * companyName;
@property NSNumber * priceChangeDollar;
@property NSNumber * priceChangePercentage;

@property TradeItTicketControllerResult * resultContainer;

@end
