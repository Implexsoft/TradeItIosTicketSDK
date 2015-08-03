//
//  TicketSession.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/13/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItStockOrEtfTradeSession.h"

@interface TicketSession : TradeItStockOrEtfTradeSession

@property BOOL debugMode;

@property double lastPrice;

@property UIViewController * parentView;
@property BOOL popToRoot;

@property NSString * errorTitle;
@property NSString * errorMessage;

@property (copy) void (^callback)(void);
@property (copy) void (^refreshLastPrice)(NSString * symbol, void(^callback)(double lastPrice));

@property NSString * calcScreenStoryboardId;

@end
