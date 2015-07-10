//
//  LoadingScreenViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/24/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItStockOrEtfTradeSession.h"
#import "ReviewScreenViewController.h"

@interface LoadingScreenViewController : UIViewController

@property NSString * actionToPerform;
@property TradeItStockOrEtfTradeSession * tradeSession;

@end
