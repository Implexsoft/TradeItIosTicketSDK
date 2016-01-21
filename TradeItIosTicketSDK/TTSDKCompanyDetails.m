//
//  CompanyDetails.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/23/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKCompanyDetails.h"
#import "TTSDKUtils.h"

@interface TTSDKCompanyDetails() {
    TTSDKUtils * utils;
}

@end

@implementation TTSDKCompanyDetails

-(id) init {
    if (self = [super init]) {
        utils = [TTSDKUtils sharedUtils];
    }

    return self;
}

-(void) populateDetailsWithSymbol: (NSString *)symbol andLastPrice:(NSNumber *)lastPrice andChange:(NSNumber *)change andChangePct:(NSNumber *)changePct {
    [self populateSymbol:symbol];
    [self populateLastPrice:lastPrice];
    [self populateChangeLabelWithChange:change andChangePct:changePct];

    [self setNeedsDisplay];
}

-(void) populateSymbol: (NSString *)symbol {
    [self.symbolLabel setTitle:symbol forState:UIControlStateNormal];
}

-(void) populateLastPrice: (NSNumber *)lastPrice {
    self.lastPriceLabel.text = [utils formatPriceString:lastPrice];
}

-(void) populateChangeLabelWithChange: (NSNumber *)change andChangePct: (NSNumber *)changePct {
    self.changeLabel.text = [NSString stringWithFormat:@"%@ %@", (change ? change : @"+3.14"), (changePct ? changePct : @"(2.53%)")];
}

-(void) populateBrokerButtonTitle:(NSString *)broker {
    [self.brokerButton setTitle:broker forState:UIControlStateNormal];
}

@end
