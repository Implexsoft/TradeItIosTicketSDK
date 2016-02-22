//
//  TTSDKPortfolioAccountsTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/7/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioAccountsTableViewCell.h"
#import "TradeItAccountOverviewResult.h"
#import "TTSDKUtils.h"

@interface TTSDKPortfolioAccountsTableViewCell() {
    TTSDKUtils * utils;
}

@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyingPowerLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

@property TTSDKPortfolioAccount * portfolioAccount;

@end

@implementation TTSDKPortfolioAccountsTableViewCell



#pragma mark - Initialization

-(void) awakeFromNib {
    [super awakeFromNib];
    utils = [TTSDKUtils sharedUtils];
}



#pragma mark - Configuration

-(void) configureCellWithAccount:(TTSDKPortfolioAccount *)account {
    NSString * displayTitle = account.displayTitle;
    NSString * totalValue;

    self.portfolioAccount = account;

    self.accountLabel.text = displayTitle;

    if (account.needsAuthentication) {
        self.authenticateView.hidden = NO;
        UITapGestureRecognizer * authTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(authSelected:)];
        [self.authenticateView addGestureRecognizer: authTap];
    } else {
        self.authenticateView.hidden = YES;
        if (account.balance.totalValue) {
            totalValue = [NSString stringWithFormat:@"%.02f", [account.balance.totalValue floatValue]];
        } else {
            totalValue = @"N/A";
        }

        NSString * buyingPower = account.balance.buyingPower ? [utils formatPriceString:account.balance.buyingPower] : @"N/A";

        self.valueLabel.text = totalValue;
        self.buyingPowerLabel.text = buyingPower;
    }
}

-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(IBAction) authSelected:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didSelectAuth:)]) {
        [self.delegate didSelectAuth: self.portfolioAccount];
    }
}

-(void) hideSeparator {
    self.separatorView.hidden = YES;
}

-(void) showSeparator {
    self.separatorView.hidden = NO;
}



@end
