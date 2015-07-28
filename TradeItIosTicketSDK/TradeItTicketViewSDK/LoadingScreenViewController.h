//
//  LoadingScreenViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/24/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TicketSession.h"
#import "TradeItResult.h"
#import "TradeItSecurityQuestionResult.h"
#import "TradeItMultipleAccountResult.h"
#import "TradeItStockOrEtfTradeReviewResult.h"
#import "TradeItStockOrEtfTradeSuccessResult.h"
#import "TradeItErrorResult.h"
#import "CustomIOSAlertView.h"

#import "TradeItVerifyCredentialSession.h"

#import "ReviewScreenViewController.h"
#import "SuccessViewController.h"
#import "CalculatorViewController.h"

@interface LoadingScreenViewController : UIViewController <UIAlertViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property NSString * actionToPerform;
@property TicketSession * tradeSession;
@property TradeItResult * lastResult;
@property TradeItStockOrEtfTradeReviewResult * reviewResult;
@property TradeItStockOrEtfTradeSuccessResult * successResult;

@property NSString * addBroker;
@property TradeItAuthenticationInfo * verifyCreds;

@end
