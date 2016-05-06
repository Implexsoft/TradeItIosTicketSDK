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

@property TradeItAuthenticationInfo * verifyCreds;
@property BOOL isModal;
@property BOOL cancelToParent;
@property BOOL reAuthenticate;
@property NSString * addBroker;
@property NSArray * questionOptions;

@property void (^onCompletion)(TradeItResult *);

@end
