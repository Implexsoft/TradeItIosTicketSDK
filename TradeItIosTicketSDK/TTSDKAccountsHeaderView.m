//
//  TTSKAccountsHeaderView.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/21/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountsHeaderView.h"
#import "TTSDKUtils.h"

@interface TTSDKAccountsHeaderView() {
    TTSDKUtils * utils;
}

@property (weak, nonatomic) IBOutlet UILabel *totalPortfolioValueLabel;

@end

@implementation TTSDKAccountsHeaderView



-(void) awakeFromNib {
    utils = [TTSDKUtils sharedUtils];
}

-(void) populateTotalPortfolioValue:(NSNumber *)value {
    self.totalPortfolioValueLabel.text = [utils formatPriceString:value];
}



@end
