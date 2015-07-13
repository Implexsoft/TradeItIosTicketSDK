//
//  SuccessViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/26/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItTicket.h"
#import "TradeItStockOrEtfTradeSession.h"
#import "TradeItStockOrEtfTradeSuccessResult.h"

@interface SuccessViewController : UIViewController

@property TradeItStockOrEtfTradeSession * tradeSession;
@property TradeItStockOrEtfTradeSuccessResult * result;

@end
