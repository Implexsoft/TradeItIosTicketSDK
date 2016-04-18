//
//  TTSDKLoginViewController.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItAuthenticationInfo.h"
#import "TradeItErrorResult.h"
#import "TradeItAuthLinkResult.h"
#import "TradeItAuthenticationResult.h"
#import "TradeItSecurityQuestionResult.h"
#import "TTSDKViewController.h"

@interface TTSDKLoginViewController : TTSDKViewController <UITextFieldDelegate, UIAlertViewDelegate>

@property BOOL cancelToParent;

@property NSString * addBroker;
@property TradeItAuthenticationInfo * verifyCreds;

@property NSArray * questionOptions;
@property NSString * currentSelection;

@property BOOL isModal;

@end
