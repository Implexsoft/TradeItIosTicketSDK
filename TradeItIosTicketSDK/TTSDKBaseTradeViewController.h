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
#import "TTSDKTradeItTicket.h"
#import "TradeItPreviewTradeRequest.h"
#import "TradeItPreviewTradeResult.h"
#import "TTSDKAccountService.h"

@interface TTSDKBaseTradeViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property TradeItResult * lastResult;

@property NSArray * pickerTitles;
@property NSArray * pickerValues;
@property UIPickerView * currentPicker;
@property NSString * currentSelection;
@property NSArray * questionOptions;
@property NSDictionary * currentAccount;

@property NSArray * currentAccountPositions;
@property TradeItAccountOverviewResult * currentAccountOverviewResult;

-(void) sendPreviewRequest;
-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message;
-(void) showOldOrderAction;
-(void) showOldOrderExp;
-(UIView *) createPickerView: (NSString *) title;
-(void) acknowledgeAlert;
-(void) retrieveQuoteData;
-(void) retrieveAccountSummaryData;

@end
