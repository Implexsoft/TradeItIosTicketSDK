//
//  TTSDKLoginViewController.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKTicketSession.h"
#import "TTSDKTradeItTicket.h"
#import "TradeItAuthenticationInfo.h"

@interface TTSDKLoginViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property TTSDKTicketSession * tradeSession;
@property BOOL cancelToParent;

@property NSString * addBroker;
@property TradeItAuthenticationInfo * verifyCreds;

@property NSArray * questionOptions;
@property NSString * currentSelection;

@end
