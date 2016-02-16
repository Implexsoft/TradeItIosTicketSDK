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



#pragma mark - Initialization

-(id) init {
    if (self = [super init]) {
        utils = [TTSDKUtils sharedUtils];
    }

    return self;
}



#pragma mark - Configuration

-(void) populateDetailsWithPosition:(TTSDKPosition *)position {

    [self populateSymbol: position.symbol];
    [self populateLastPrice: position.lastPrice];
    [self populateChangeLabelWithChange:position.change andChangePct:position.changePct];
}

-(void) populateSymbol: (NSString *)symbol {
    if (symbol) {
        [self.symbolLabel setTitle:symbol forState:UIControlStateNormal];
    } else {
        [self.symbolLabel setTitle:@"N/A" forState:UIControlStateNormal];
    }
}

-(void) populateLastPrice: (NSNumber *)lastPrice {
    if (lastPrice && (lastPrice > 0)) {
        self.lastPriceLabel.text = [utils formatPriceString:lastPrice];
        self.lastPriceLabel.hidden = NO;
    } else {
        self.lastPriceLabel.hidden = YES;
    }
}

-(void) populateChangeLabelWithChange: (NSNumber *)change andChangePct: (NSNumber *)changePct {
    if (change != nil && ![change isEqual: @0] && changePct != nil && ![changePct isEqual: @0]) {

        NSString * changePrefix;
        UIColor * changeColor;
        if (change > 0) {
            changePrefix = @"+";
            changeColor = [utils gainColor];
        } else {
            changePrefix = @"";
            changeColor = [utils lossColor];
        }

        self.changeLabel.text = [NSString stringWithFormat:@"%@%@ (%@%@)", changePrefix, change, changePct, @"%"];
        self.changeLabel.textColor = changeColor;
        self.changeLabel.hidden = NO;
    } else {
        self.changeLabel.hidden = YES;
    }
}

-(void) populateBrokerButtonTitle:(NSString *)broker {
    if (broker) {
        [self.brokerButton setTitle:broker forState:UIControlStateNormal];
    } else {
        [self.brokerButton setTitle:@"N/A" forState:UIControlStateNormal];
    }
}

-(void) populateSymbolDetail:(NSNumber *)buyingPower andSharesOwned:(NSNumber *)sharesOwned {
    if (!buyingPower && !sharesOwned) {
        self.symbolDetailLabel.hidden = YES;
        self.symbolDetailValue.hidden = YES;
    } else {
        self.symbolDetailLabel.hidden = NO;
        self.symbolDetailValue.hidden = NO;

        if (buyingPower) {
            self.symbolDetailLabel.text = @"BUYING POWER";
            self.symbolDetailValue.text = [NSString stringWithFormat:@"$%@", buyingPower];
        } else if (sharesOwned) {
            self.symbolDetailLabel.text = @"SHARES OWNED";
            self.symbolDetailValue.text = [NSString stringWithFormat:@"%@", sharesOwned];
        }
    }

}



@end
