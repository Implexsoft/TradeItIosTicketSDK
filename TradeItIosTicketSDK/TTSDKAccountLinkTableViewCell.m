//
//  TTSDKAccountLinkTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/13/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountLinkTableViewCell.h"
#import "TTSDKUtils.h"

@interface TTSDKAccountLinkTableViewCell()


@property (unsafe_unretained, nonatomic) IBOutlet UILabel * buyingPowerLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel * accountTypeLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UIView * circleGraphic;
@property TTSDKUtils * utils;

@end

@implementation TTSDKAccountLinkTableViewCell

-(void) awakeFromNib {
    // Initialization code

    self.utils = [TTSDKUtils sharedUtils];
}

-(IBAction) togglePressed:(id)sender {
    NSLog(@"setting linked inside custom object class");
    self.linked = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkToggleDidSelect)]) {
        [self.delegate linkToggleDidSelect];
    }
}

-(void) configureCellWithData:(NSDictionary *)data {
    NSString * buyingPower = [data valueForKey:@"buyingPower"];
    NSString * accountType = [data valueForKey:@"accountType"];
    self.accountName = [data valueForKey:@"accountName"];
    NSString * linkedStr = [data valueForKey:@"linked"];
    self.linked = [linkedStr intValue];

    NSString * broker = [data objectForKey:@"broker"];

    if (!broker) {
        broker = @"Fidelity";
    }

    self.toggle.on = self.linked;
    self.buyingPowerLabel.text = buyingPower;
    self.accountTypeLabel.text = accountType;
    self.accountNameLabel.text = self.accountName;

    UIColor * brokerColor = [self.utils retrieveBrokerColorByBrokerName:broker];

    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = brokerColor.CGColor;
}

@end
