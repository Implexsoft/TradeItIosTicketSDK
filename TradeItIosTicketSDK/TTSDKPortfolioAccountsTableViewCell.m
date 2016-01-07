//
//  TTSDKPortfolioAccountsTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/7/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioAccountsTableViewCell.h"

@interface TTSDKPortfolioAccountsTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyingPowerLabel;


@end

@implementation TTSDKPortfolioAccountsTableViewCell

-(void) awakeFromNib {
}

-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(void) configureCellWithData:(NSDictionary *)data {
    NSString * accountName = [data valueForKey:@"acctName"];
    NSString * totalValue = [data valueForKey:@"totalValue"];
    NSString * buyingPower = [data valueForKey:@"buyingPower"];

    self.accountLabel.text = accountName;
    self.valueLabel.text = totalValue;
    self.buyingPowerLabel.text = buyingPower;
}

@end
