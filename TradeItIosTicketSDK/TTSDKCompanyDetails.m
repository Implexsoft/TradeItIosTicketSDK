//
//  CompanyDetails.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/23/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKCompanyDetails.h"
#import "TTSDKUtils.h"
#import "TradeItStyles.h"
#import "TTSDKTradeItTicket.h"

@interface TTSDKCompanyDetails() {
    TTSDKTradeItTicket * globalTicket;
    TTSDKUtils * utils;
    TradeItStyles * styles;
    UIView * priceLoadingView;
    UIView * accountLoadingView;
    UIColor * lastPriceLabelColor;
}
@property (weak, nonatomic) IBOutlet UIImageView *rightArrow;

@end

@implementation TTSDKCompanyDetails


#pragma mark Initialization

-(id) init {
    if (self = [super init]) {
        globalTicket = [TTSDKTradeItTicket globalTicket];
        utils = [TTSDKUtils sharedUtils];
        [self setViewStyles];
    }

    return self;
}

-(void) setViewStyles {
    styles = [TradeItStyles sharedStyles];

    [self.symbolLabel setTitleColor:styles.activeColor forState:UIControlStateNormal];
    [self.brokerButton setTitleColor:styles.primaryTextColor forState:UIControlStateNormal];

    self.rightArrow.image = [self.rightArrow.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.rightArrow.tintColor = styles.activeColor;

    self.symbolDetailLabel.textColor = styles.smallTextColor;

    priceLoadingView = [utils retrieveLoadingOverlayForView:self.lastPriceLabel withRadius:10.0f];
    [self.lastPriceLabel addSubview: priceLoadingView];

    lastPriceLabelColor = self.lastPriceLabel.textColor;

    accountLoadingView = [utils retrieveLoadingOverlayForView:self.symbolDetailLabel withRadius: 10.0f];
    [self.symbolDetailValue addSubview: accountLoadingView];
}


#pragma mark Configuration

-(void) populateDetailsWithQuote:(TradeItQuote *)quote {
    [self populateSymbol: quote.symbol];
    [self populateLastPrice: quote.lastPrice];
    [self populateChangeLabelWithChange:quote.change andChangePct:quote.pctChange];
}

-(void) populateSymbol: (NSString *)symbol {
    if (globalTicket.quote.symbol) {
        [self.symbolLabel setTitle:globalTicket.quote.symbol forState:UIControlStateNormal];
    } else {
        [self.symbolLabel setTitle:@"Select Symbol" forState:UIControlStateNormal];

        if (priceLoadingView) {
            priceLoadingView.hidden = YES;
        }
    }
}

-(void) populateLastPrice: (NSNumber *)lastPrice {
    NSNumber * theLastPrice = globalTicket.quote.lastPrice;
    if (theLastPrice && (theLastPrice > 0)) {
        self.lastPriceLabel.text = [utils formatPriceString:theLastPrice];
        self.lastPriceLabel.textColor = lastPriceLabelColor;
        priceLoadingView.hidden = YES;
    } else {
        if (globalTicket.loadingQuote) {
            self.lastPriceLabel.text = @"";
            priceLoadingView.hidden = NO;
        } else {
            self.lastPriceLabel.text = @"N/A";
            self.lastPriceLabel.textColor = styles.inactiveColor;
            priceLoadingView.hidden = YES;
        }
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
        self.changeLabel.textColor = styles.inactiveColor;
        self.changeLabel.text = @"";
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
        if (accountLoadingView) {
            accountLoadingView.hidden = NO;
        }
    } else {
        self.symbolDetailLabel.hidden = NO;
        [accountLoadingView removeFromSuperview];

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
