//
//  CompanyDetails.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/23/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKCompanyDetails.h"
#import "TTSDKHelper.h"

@interface TTSDKCompanyDetails() {
    TTSDKHelper * helper;
}

@end

@implementation TTSDKCompanyDetails

-(id) init {
    if (self = [super init]) {
        helper = [TTSDKHelper sharedHelper];
    }

    return self;
}

-(void) populateDetailsWithSymbol: (NSString *)symbol andLastPrice:(NSNumber *)lastPrice andChange:(NSNumber *)change andChangePct:(NSNumber *)changePct {
    [self populateSymbol:symbol];
    [self populateLastPrice:lastPrice];
    [self populateChangeLabelWithChange:change andChangePct:changePct];
}

-(void) populateSymbol: (NSString *)symbol {
    self.symbolLabel.titleLabel.text = symbol;
}

-(void) populateLastPrice: (NSNumber *)lastPrice {
    self.lastPriceLabel.text = [helper formatPriceString:lastPrice];
}

-(void) populateChangeLabelWithChange: (NSNumber *)change andChangePct: (NSNumber *)changePct {
    self.changeLabel.text = [NSString stringWithFormat:@"%@ %@", (change ? change : nil), (changePct ? changePct : nil)];
}

@end
