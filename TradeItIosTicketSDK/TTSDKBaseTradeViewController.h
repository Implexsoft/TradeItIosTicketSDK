//
//  BaseCalculatorViewController.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKCustomIOSAlertView.h"
#import "TTSDKUtils.h"
#import "TTSDKTicketController.h"
#import "TradeItPreviewTradeRequest.h"
#import "TradeItPreviewTradeResult.h"

@interface TTSDKBaseTradeViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property TradeItResult * lastResult;

@property NSArray * pickerTitles;
@property NSArray * pickerValues;
@property UIPickerView * currentPicker;
@property NSString * currentSelection;
@property NSArray * questionOptions;
@property NSDictionary * currentAccount;

-(void) sendPreviewRequest;
-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message;
-(void) showOldOrderAction;
-(void) showOldOrderExp;
-(UIView *) createPickerView: (NSString *) title;
-(void) acknowledgeAlert;

@end
