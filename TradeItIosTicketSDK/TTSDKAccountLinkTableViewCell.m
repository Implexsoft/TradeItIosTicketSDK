//
//  TTSDKAccountLinkTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/13/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountLinkTableViewCell.h"
#import "TTSDKUtils.h"
#import "TTSDKTicketController.h"

@interface TTSDKAccountLinkTableViewCell() {
    TTSDKUtils * utils;
    NSDictionary * accountData;
    TTSDKTicketController * globalController;
}

@property (unsafe_unretained, nonatomic) IBOutlet UILabel * buyingPowerLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel * accountTypeLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UIView * circleGraphic;

@end

@implementation TTSDKAccountLinkTableViewCell



#pragma mark - Initialization

-(void) awakeFromNib {
    utils = [TTSDKUtils sharedUtils];
    globalController = [TTSDKTicketController globalController];
}



#pragma mark - Configuration

-(void) configureCellWithData:(NSDictionary *)data {
    accountData = data;

    NSString * buyingPower = [data valueForKey:@"buyingPower"] ? [data valueForKey:@"buyingPower"] : @"100";
    NSString * accountType = [data valueForKey:@"accountType"] ? [data valueForKey:@"accountType"] : @"Brokerage";
    self.accountName = [data valueForKey:@"name"];
    NSString * linkedStr = [data valueForKey:@"active"];
    BOOL linked = [linkedStr boolValue];

    NSString * broker = [data objectForKey:@"broker"] ? [data objectForKey:@"broker"] : @"N/A";

    self.toggle.on = linked;
    self.buyingPowerLabel.text = buyingPower;
    self.accountTypeLabel.text = accountType;
    self.accountNameLabel.text = self.accountName;

    UIColor * brokerColor = [utils retrieveBrokerColorByBrokerName:broker];

    CAShapeLayer * circleLayer = [utils retrieveCircleGraphicWithSize:(self.circleGraphic.frame.size.width - 1) andColor:brokerColor];
    self.circleGraphic.backgroundColor = [UIColor clearColor];
    [self.circleGraphic.layer addSublayer:circleLayer];
}



#pragma mark - Custom Recognizers

-(IBAction) togglePressed:(id)sender {
    // If the toggle resulted in unlinking the account, make sure the account can be unlinked
    if (!self.toggle.on) {
        NSArray * linkedAccounts = [globalController retrieveLinkedAccounts];
        if (linkedAccounts.count < 2) {
            self.toggle.on = YES;
            [self.delegate linkToggleDidNotSelect: @"You must have at least one linked account to trade."];
            return;
        } else if ([accountData isEqualToDictionary:globalController.currentSession.currentAccount]) {
            self.toggle.on = YES;
            [self.delegate linkToggleDidNotSelect: @"This account is currently selected."];
            return;
        }
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(linkToggleDidSelect:)]) {
        [self.delegate linkToggleDidSelect: accountData];
    }
}

-(void) callLinkToggleDidNotSelect {
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkToggleDidNotSelect:)]) {
        [self.delegate linkToggleDidNotSelect: @""];
    }
}


@end
