//
//  TTSDKViewController.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 4/6/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItStyles.h"
#import "TTSDKCustomIOSAlertView.h"

@interface TTSDKViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property TradeItStyles * styles;
@property NSArray * pickerTitles;
@property NSArray * pickerValues;
@property UIPickerView * currentPicker;
@property NSString * currentSelection;

-(void) setViewStyles;
-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message;
-(void) showPicker:(NSString *)pickerTitle withSelection:(NSString *)selection andOptions:(NSArray *)options onSelection:(void (^)(void))selectionBlock;
-(UIView *) createPickerView: (NSString *) title;

@end
