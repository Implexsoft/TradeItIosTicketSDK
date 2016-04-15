//
//  CompanyDetails.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/23/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKCompanyDetails.h"
#import "TTSDKUtils.h"
#import "TTSDKStyles.h"

@interface TTSDKCompanyDetails() {
    TTSDKUtils * utils;
    TTSDKStyles * styles;
}
@property (weak, nonatomic) IBOutlet UIImageView *rightArrow;

@end

@implementation TTSDKCompanyDetails



#pragma mark - Initialization

-(id) init {
    if (self = [super init]) {
        utils = [TTSDKUtils sharedUtils];
        
        [self setViewStyles];
    }

    return self;
}

-(void) setViewStyles {
    styles = [TTSDKStyles sharedStyles];

    [self.symbolLabel setTitleColor:styles.activeColor forState:UIControlStateNormal];
    [self.brokerButton setTitleColor:styles.primaryTextColor forState:UIControlStateNormal];

    self.rightArrow.image = [self.rightArrow.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.rightArrow.tintColor = styles.activeColor;

    self.symbolDetailLabel.textColor = styles.smallTextColor;
}



#pragma mark - Configuration

-(void) populateDetailsWithQuote:(TradeItQuote *)quote {
    [self populateSymbol: quote.symbol];
    [self populateLastPrice: quote.lastPrice];
    [self populateChangeLabelWithChange:quote.change andChangePct:quote.pctChange];
}

-(void) populateSymbol: (NSString *)symbol {
    if (symbol) {
        [self.symbolLabel setTitle:symbol forState:UIControlStateNormal];
    } else {
        [self.symbolLabel setTitle:@"Select Symbol" forState:UIControlStateNormal];
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
        if ([change floatValue] > 0) {
            changePrefix = @"+";
            changeColor = styles.gainColor;
        } else {
            changePrefix = @"";
            changeColor = styles.lossColor;
        }

        self.changeLabel.text = [NSString stringWithFormat:@"%@%.02f (%.02f%@)", changePrefix, [change floatValue], [changePct floatValue], @"%"];
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
            self.symbolDetailValue.text = [utils formatPriceString: buyingPower];
        } else if (sharesOwned) {
            self.symbolDetailLabel.text = @"SHARES OWNED";
            self.symbolDetailValue.text = [NSString stringWithFormat:@"%@", sharesOwned];
        }
    }
}



@end
