//
//  TTSKAccountsHeaderView.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/21/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountsHeaderView.h"
#import "TTSDKUtils.h"
#import "TTSDKStyles.h"

@interface TTSDKAccountsHeaderView() {
    TTSDKUtils * utils;
    TTSDKStyles * styles;
}

@property (weak, nonatomic) IBOutlet UILabel *totalPortfolioValueLabel;

@end

@implementation TTSDKAccountsHeaderView



-(void) awakeFromNib {
    utils = [TTSDKUtils sharedUtils];
    styles = [TTSDKStyles sharedStyles];

    [self.editAccountsButton setTitleColor:styles.activeColor forState:UIControlStateNormal];
}

-(void) populateTotalPortfolioValue:(NSNumber *)value {
    self.totalPortfolioValueLabel.text = [utils formatPriceString:value];
}



@end
