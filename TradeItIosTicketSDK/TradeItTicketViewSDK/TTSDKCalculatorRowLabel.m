//
//  CalculatorRowLabels.m
//  Ticket
//
//  Created by Antonio Reyes on 6/17/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKCalculatorRowLabel.h"

@interface TTSDKCalculatorRowLabel() {
    NSString * _label;
    NSString * _defaultValue;
    NSString * _format;
}

@end

@implementation TTSDKCalculatorRowLabel

- (instancetype) initWithDefaultValue:(NSString *)defaultValue
                                label:(NSString *)label
                               format:(NSString *)format
                              uiLabel:(UIButton *)uiLabel
                              uiValue:(UIButton *)uiButton {
    self = [super init];
    
    if (self) {
        _label = label;
        _defaultValue = defaultValue;
        _format = format;
        _uiLabel = uiLabel;
        _uiButton = uiButton;
        _currentValueStack = @"";
    }
    
    return self;
}

-(void) setDefaultsToUI {
    [self setUIToStack];
    [self.uiLabel setTitle:_label forState:UIControlStateNormal];
}

-(void) setUIToStack {
    NSString * value = _currentValueStack;
    
    if([value isEqual: @""]) {
        value = _defaultValue;
    }
    else if(![_label isEqual:@"Shares"]) {
        double doubleValue = [value doubleValue];
        
        if(![TTSDKTradeItTicket containsString:value searchString:@"."]) {
            value = [NSString stringWithFormat:@"%@.00", value];
        } else if(doubleValue < 1 && doubleValue > 0) {
            if([[_currentValueStack substringFromIndex:[_currentValueStack rangeOfString:@"."].location] length] > 5) {
                _currentValueStack = [_currentValueStack substringToIndex:[_currentValueStack length] - 1];
                return;
            } else {
                value = [NSString stringWithFormat:@"%.4f", doubleValue];
            }
        } else {
            if([[_currentValueStack substringFromIndex:[_currentValueStack rangeOfString:@"."].location] length] > 3) {
                _currentValueStack = [_currentValueStack substringToIndex:[_currentValueStack length] - 1];
                return;
            } else {
                value = [NSString stringWithFormat:@"%.2f", doubleValue];
            }
        }
    }
    
    [self.uiButton setTitle:[self formatValue:value] forState:UIControlStateNormal];
}

-(NSString *) formatValue:(NSString *)value {
    return [NSString stringWithFormat:_format, value];
}

-(void) setActive {
    [self.uiLabel setTitleColor:[TTSDKTradeItTicket activeColor] forState:UIControlStateNormal];
    [self.uiButton setTitleColor:[TTSDKTradeItTicket activeColor] forState:UIControlStateNormal];
}

-(void) setPassive {
    [self.uiLabel setTitleColor:[TTSDKTradeItTicket baseTextColor] forState:UIControlStateNormal];
    [self.uiButton setTitleColor:[TTSDKTradeItTicket baseTextColor] forState:UIControlStateNormal];
}

+(TTSDKCalculatorRowLabel *) getSharesLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue {
    return [[TTSDKCalculatorRowLabel alloc] initWithDefaultValue:@"0"
                                                      label:@"Shares"
                                                     format:@"%@"
                                                    uiLabel:uiLabel
                                                    uiValue:uiValue];
}

+(TTSDKCalculatorRowLabel *) getLastPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue {
    return [[TTSDKCalculatorRowLabel alloc] initWithDefaultValue:@"0.00"
                                                      label:@"Last Price"
                                                     format:@"$%@"
                                                    uiLabel:uiLabel
                                                    uiValue:uiValue];
}

+(TTSDKCalculatorRowLabel *) getLimitPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue {
    return [[TTSDKCalculatorRowLabel alloc] initWithDefaultValue:@"0.00"
                                                      label:@"Limit Price"
                                                     format:@"$%@"
                                                    uiLabel:uiLabel
                                                    uiValue:uiValue];
}

+(TTSDKCalculatorRowLabel *) getStopPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue {
    return [[TTSDKCalculatorRowLabel alloc] initWithDefaultValue:@"0.00"
                                                      label:@"Stop Price"
                                                     format:@"$%@"
                                                    uiLabel:uiLabel
                                                    uiValue:uiValue];
}

+(TTSDKCalculatorRowLabel *) getStopLimitPriceLabel:(UIButton *)uiLabel uiValue:(UIButton *)uiValue {
    return [[TTSDKCalculatorRowLabel alloc] initWithDefaultValue:@"0.00"
                                                      label:@"Stop Price"
                                                     format:@"($%@)"
                                                    uiLabel:uiLabel
                                                    uiValue:uiValue];
}

@end