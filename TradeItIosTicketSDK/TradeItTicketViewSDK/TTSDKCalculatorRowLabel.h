//
//  CalculatorRowLabels.h
//  Ticket
//
//  Created by Antonio Reyes on 6/17/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TTSDKTradeItTicket.h"

@interface TTSDKCalculatorRowLabel : NSObject

@property UIButton * uiLabel;
@property UIButton * uiButton;
@property NSString * currentValueStack;

-(void) setDefaultsToUI;
-(void) setUIToStack;
-(void) setActive;
-(void) setPassive;

+(TTSDKCalculatorRowLabel *) getSharesLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue;
+(TTSDKCalculatorRowLabel *) getLastPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue;
+(TTSDKCalculatorRowLabel *) getLimitPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue;
+(TTSDKCalculatorRowLabel *) getStopPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue;
+(TTSDKCalculatorRowLabel *) getStopLimitPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue;

@end
