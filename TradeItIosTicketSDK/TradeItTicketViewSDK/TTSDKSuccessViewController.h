//
//  SuccessViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/26/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKTradeItTicket.h"
#import "TradeItStockOrEtfTradeSuccessResult.h"
#import "TTSDKTicketSession.h"

@interface TTSDKSuccessViewController : UIViewController

@property TTSDKTicketSession * tradeSession;
@property TradeItStockOrEtfTradeSuccessResult * result;

@end
