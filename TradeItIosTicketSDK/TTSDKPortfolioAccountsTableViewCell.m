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

@end

@implementation TTSDKPortfolioAccountsTableViewCell



#pragma mark - Initialization

-(void) awakeFromNib {
    [super awakeFromNib];
}



#pragma mark - Configuration

-(void) configureCellWithDetails:(NSDictionary *)data {

    NSString * displayTitle = [data valueForKey:@"displayTitle"];

    TradeItAccountOverviewResult * overview = (TradeItAccountOverviewResult *)[data valueForKey:@"overview"];
    NSString * totalValue = [overview.totalValue stringValue];
    NSString * buyingPower = [overview.buyingPower stringValue];

    self.accountLabel.text = displayTitle;
    self.valueLabel.text = totalValue;
    self.buyingPowerLabel.text = buyingPower;
}


-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}



@end
