//
//  TTSDKPortfolioAccountsTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/7/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioAccountsTableViewCell.h"
#import "TradeItAccountOverviewResult.h"

@interface TTSDKPortfolioAccountsTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyingPowerLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

@end

@implementation TTSDKPortfolioAccountsTableViewCell



#pragma mark - Initialization

-(void) awakeFromNib {
    [super awakeFromNib];
}



#pragma mark - Configuration

-(void) configureCellWithAccount:(TTSDKPortfolioAccount *)account {

    NSString * displayTitle = account.displayTitle;

    NSString * totalValue;
    if (account.balance.totalValue) {
        totalValue = [NSString stringWithFormat:@"%.02f", [account.balance.totalValue floatValue]];
    } else {
        totalValue = @"N/A";
    }

    NSString * buyingPower = [account.balance.buyingPower stringValue];

    self.accountLabel.text = displayTitle;
    self.valueLabel.text = totalValue;
    self.buyingPowerLabel.text = buyingPower;
}


-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(void) hideSeparator {
    self.separatorView.hidden = YES;
}

-(void) showSeparator {
    self.separatorView.hidden = NO;
}



@end
