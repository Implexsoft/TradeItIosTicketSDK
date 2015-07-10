//
//  CalculatorRowLabels.h
//  Ticket
//
//  Created by Antonio Reyes on 6/17/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TradeItTicket.h"

@interface CalculatorRowLabel : NSObject

@property UIButton * uiLabel;
@property UIButton * uiButton;
@property NSString * currentValueStack;

-(void) setDefaultsToUI;
-(void) setUIToStack;
-(void) setActive;
-(void) setPassive;

+(CalculatorRowLabel *) getSharesLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue;
+(CalculatorRowLabel *) getLastPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue;
+(CalculatorRowLabel *) getLimitPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue;
+(CalculatorRowLabel *) getStopPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue;
+(CalculatorRowLabel *) getStopLimitPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue;

@end
