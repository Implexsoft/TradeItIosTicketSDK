//
//  LoadingScreenViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/24/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItStockOrEtfTradeSession.h"
#import "TradeItResult.h"
#import "TradeItSecurityQuestionResult.h"
#import "TradeItMultipleAccountResult.h"
#import "TradeItStockOrEtfTradeReviewResult.h"
#import "TradeItStockOrEtfTradeSuccessResult.h"
#import "TradeItErrorResult.h"

#import "ReviewScreenViewController.h"
#import "SuccessViewController.h"

@interface LoadingScreenViewController : UIViewController

@property NSString * actionToPerform;
@property TradeItStockOrEtfTradeSession * tradeSession;
@property TradeItStockOrEtfTradeReviewResult * reviewResult;
@property TradeItStockOrEtfTradeSuccessResult * successResult;

@end
