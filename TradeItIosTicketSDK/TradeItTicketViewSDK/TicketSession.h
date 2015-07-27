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

@property (copy) void (^callback)(void);
@property double lastPrice;
@property UIViewController * parentView;
@property NSString * orderType;
@property BOOL popToRoot;
@property BOOL debugMode;

@property NSString * errorTitle;
@property NSString * errorMessage;

@end
