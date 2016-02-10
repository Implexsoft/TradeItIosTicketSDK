//
//  ReviewScreenViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/24/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKTicketSession.h"
#import "TradeItPreviewTradeResult.h"

@interface TTSDKReviewScreenViewController : UIViewController

@property TTSDKTicketSession * tradeSession;
@property TradeItPreviewTradeResult * reviewTradeResult;


//@property TradeItStockOrEtfTradeSuccessResult * successResult;

@end
