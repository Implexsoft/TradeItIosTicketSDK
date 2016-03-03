//
//  TTSDKAccountLinkTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/13/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountLinkTableViewCell.h"
#import "TTSDKUtils.h"
#import "TTSDKTradeItTicket.h"


@interface TTSDKAccountLinkTableViewCell() {
    TTSDKUtils * utils;
    TTSDKPortfolioAccount * account;
    TTSDKTradeItTicket * globalTicket;
}

@property (unsafe_unretained, nonatomic) IBOutlet UILabel * buyingPowerLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel * accountTypeLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UIView * circleGraphic;

@end

@implementation TTSDKAccountLinkTableViewCell



#pragma mark - Initialization

-(void) awakeFromNib {
    utils = [TTSDKUtils sharedUtils];
    globalTicket = [TTSDKTradeItTicket globalTicket];
}



#pragma mark - Configuration

-(void) configureCellWithAccount:(TTSDKPortfolioAccount *)portfolioAccount {
    account = portfolioAccount;

    self.accountName = account.accountNumber;
    self.accountNameLabel.text = self.accountName;

    self.buyingPowerLabel.text = account.balance.buyingPower != nil ? [utils formatPriceString:account.balance.buyingPower] : @"N/A";

    self.toggle.on = account.active;

    NSString * broker = account.broker ?: @"N/A";

    self.accountTypeLabel.text = broker;
    UIColor * brokerColor = [utils retrieveBrokerColorByBrokerName:broker];
    CAShapeLayer * circleLayer = [utils retrieveCircleGraphicWithSize:(self.circleGraphic.frame.size.width - 1) andColor:brokerColor];
    self.circleGraphic.backgroundColor = [UIColor clearColor];
    [self.circleGraphic.layer addSublayer:circleLayer];
}



#pragma mark - Custom Recognizers

-(IBAction) togglePressed:(id)sender {

    NSDictionary * accountData = [account accountData];

    // If the toggle resulted in unlinking the account, make sure the account can be unlinked
    if (!self.toggle.on) {
        NSArray * linkedAccounts = globalTicket.linkedAccounts;
        if (linkedAccounts.count < 2) {
            self.toggle.on = YES;
            [self.delegate linkToggleDidNotSelect: @"You must have at least one linked account to trade."];
            return;
        } else if ([accountData isEqualToDictionary:globalTicket.currentAccount]) {
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
