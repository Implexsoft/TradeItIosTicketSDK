//
//  ReviewScreenViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/24/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItStockOrEtfTradeSession.h"
#import "TradeItStockOrEtfTradeReviewResult.h"
#import "LoadingScreenViewController.h"

@interface ReviewScreenViewController : UIViewController

@property TradeItStockOrEtfTradeSession * tradeSession;
@property TradeItStockOrEtfTradeReviewResult * result;

@end
