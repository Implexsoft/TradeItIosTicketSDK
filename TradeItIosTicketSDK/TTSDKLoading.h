//
//  TTSDKLoading.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/11/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
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

@interface TTSDKLoading : NSObject

@property NSString * actionToPerform;
@property TTSDKTicketSession * tradeSession;
@property TradeItResult * lastResult;
@property TradeItStockOrEtfTradeReviewResult * reviewResult;
@property TradeItStockOrEtfTradeSuccessResult * successResult;

@property NSString * addBroker;
@property TradeItAuthenticationInfo * verifyCreds;
@property UIViewController * viewController;

-(instancetype) initWithViewController: (UIViewController *)vc;

@end
