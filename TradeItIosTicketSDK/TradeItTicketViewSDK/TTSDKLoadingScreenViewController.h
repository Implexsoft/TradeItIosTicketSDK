//
//  LoadingScreenViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/24/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKTicketSession.h"
#import "TradeItResult.h"
#import "TradeItSecurityQuestionResult.h"
#import "TradeItMultipleAccountResult.h"
#import "TradeItStockOrEtfTradeReviewResult.h"
#import "TradeItStockOrEtfTradeSuccessResult.h"
#import "TradeItErrorResult.h"
#import "TTSDKCustomIOSAlertView.h"

#import "TradeItVerifyCredentialSession.h"

#import "TTSDKReviewScreenViewController.h"
#import "TTSDKSuccessViewController.h"
#import "TTSDKCalculatorViewController.h"

@interface TTSDKLoadingScreenViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UIAlertViewDelegate>

@property NSString * actionToPerform;
@property TTSDKTicketSession * tradeSession;
@property TradeItResult * lastResult;
@property TradeItStockOrEtfTradeReviewResult * reviewResult;
@property TradeItStockOrEtfTradeSuccessResult * successResult;

@property NSString * addBroker;
@property TradeItAuthenticationInfo * verifyCreds;

@end
