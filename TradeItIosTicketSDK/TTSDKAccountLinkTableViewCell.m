//
//  TTSDKAccountLinkTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/13/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountLinkTableViewCell.h"
#import "TTSDKUtils.h"

@interface TTSDKAccountLinkTableViewCell() {
    TTSDKUtils * utils;
    NSDictionary * accountData;
}


@property (unsafe_unretained, nonatomic) IBOutlet UILabel * buyingPowerLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel * accountTypeLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UIView * circleGraphic;

@end

@implementation TTSDKAccountLinkTableViewCell

-(void) awakeFromNib {
    // Initialization code

    utils = [TTSDKUtils sharedUtils];
}

-(IBAction) togglePressed:(id)sender {
    self.linked = NO;

    if (self.delegate && [self.delegate respondsToSelector:@selector(linkToggleDidSelect:)]) {
        [self.delegate linkToggleDidSelect: accountData];
    }
}

-(void) configureCellWithData:(NSDictionary *)data {

    accountData = data;

    NSString * buyingPower = [data valueForKey:@"buyingPower"] ? [data valueForKey:@"buyingPower"] : @"100";
    NSString * accountType = [data valueForKey:@"accountType"] ? [data valueForKey:@"accountType"] : @"Brokerage";
    self.accountName = [data valueForKey:@"name"];
    NSString * linkedStr = [data valueForKey:@"active"];
    self.linked = [linkedStr intValue];

    NSString * broker = [data objectForKey:@"broker"] ? [data objectForKey:@"broker"] : @"N/A";

    self.toggle.on = self.linked;
    self.buyingPowerLabel.text = buyingPower;
    self.accountTypeLabel.text = accountType;
    self.accountNameLabel.text = self.accountName;

    UIColor * brokerColor = [utils retrieveBrokerColorByBrokerName:broker];

    CAShapeLayer * circleLayer = [utils retrieveCircleGraphicWithSize:(self.circleGraphic.frame.size.width - 1) andColor:brokerColor];
    self.circleGraphic.backgroundColor = [UIColor clearColor];
    [self.circleGraphic.layer addSublayer:circleLayer];
}

@end
