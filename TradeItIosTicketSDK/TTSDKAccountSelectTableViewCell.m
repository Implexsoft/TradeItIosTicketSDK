//
//  TTSDKAccountSelectTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/16/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountSelectTableViewCell.h"
#import "TTSDKTradeItTicket.h"
#import "TTSDKUtils.h"
#import "TradeItStyles.h"

@interface TTSDKAccountSelectTableViewCell() {
    TTSDKUtils * utils;
    TTSDKTradeItTicket * globalTicket;
}
@property (weak, nonatomic) IBOutlet UILabel *buyingPower;
@property (weak, nonatomic) IBOutlet UILabel *shares;

@property (unsafe_unretained, nonatomic) IBOutlet UIView * circle;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel * brokerLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel * accountTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *buyingPowerLabel;
@property (weak, nonatomic) IBOutlet UILabel *sharesLabel;

@end

@implementation TTSDKAccountSelectTableViewCell


-(void) awakeFromNib {
    // Initialization code
    if (self) {
        self.contentView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.detailTextLabel.textColor = [UIColor colorWithRed:0.592 green:0.592 blue:0.592 alpha:1];

        self.indentationLevel = 6;

        if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
            [self setSeparatorInset:UIEdgeInsetsMake(0, 20, 0, 20)];
        }
        
        if ([self respondsToSelector:@selector(setLayoutMargins:)]) {
            [self setLayoutMargins:UIEdgeInsetsMake(0, 20, 0, 20)];
        }

        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.selected = NO;
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height)];
        self.selectedBackgroundView.backgroundColor = [UIColor clearColor];

        TradeItStyles * styles = [TradeItStyles sharedStyles];
        self.buyingPower.textColor = styles.smallTextColor;
        self.shares.textColor = styles.smallTextColor;
        self.accountTypeLabel.textColor = styles.primaryTextColor;

        utils = [TTSDKUtils sharedUtils];
        globalTicket = [TTSDKTradeItTicket globalTicket];
    }
}

-(void) configureCellWithAccountData:(NSDictionary *)data {
    self.brokerLabel.text = [data valueForKey: @"accountNumber"];
    self.brokerLabel.frame = CGRectMake(self.textLabel.frame.origin.x + 40, self.textLabel.frame.origin.y, self.brokerLabel.frame.size.width, self.textLabel.frame.size.height);

    NSString * broker = [data valueForKey:@"broker"];

    TradeItAccountOverviewResult * overview = (TradeItAccountOverviewResult *)[data valueForKey: @"overview"];

    self.buyingPowerLabel.text = [utils formatPriceString:overview.buyingPower] ?: @"N/A";
    self.sharesLabel.text = @"N/A";

    self.accountTypeLabel.text = [globalTicket getBrokerDisplayString: broker];
    [self insertPortfolioDetail: broker];
}

-(void) configureCellWithAccount:(TTSDKPortfolioAccount *)account {
    self.brokerLabel.text = account.accountNumber;
    self.brokerLabel.frame = CGRectMake(self.textLabel.frame.origin.x + 40, self.textLabel.frame.origin.y, self.brokerLabel.frame.size.width, self.textLabel.frame.size.height);

    self.buyingPowerLabel.text = account.balance.buyingPower != nil ? [utils formatPriceString:account.balance.buyingPower] : @"N/A";

    NSString * symbol = globalTicket.quote.symbol;
    NSString * shares;
    for (TTSDKPosition * position in account.positions) {
        if ([position.symbol isEqualToString: symbol]) {
            shares = [position.quantity stringValue];
            break;
        }
    }

    self.sharesLabel.text = shares ?: @"0";

    self.accountTypeLabel.text = [globalTicket getBrokerDisplayString: account.broker];
    [self insertPortfolioDetail: account.broker];
}

-(void) insertPortfolioDetail:(NSString *)broker {
    self.circle.backgroundColor = [UIColor clearColor];
    CGFloat alertSize = self.circle.frame.size.height - 3;

    CAShapeLayer *circleLayer;

    BOOL isNewLayer = YES;

    for (id item in self.circle.layer.sublayers) {
        if ([NSStringFromClass([item class]) isEqualToString:@"CAShapeLayer"]) {
            circleLayer = item;
            isNewLayer = NO;

            break;
        }
    }

    UIColor * circleFill = [utils retrieveBrokerColorByBrokerName:broker];

    if (!circleLayer) {
        circleLayer = [utils retrieveCircleGraphicWithSize:alertSize andColor:circleFill];
    } else {
        [circleLayer setFillColor: circleFill.CGColor];
    }

    if (isNewLayer) {
        [self.circle.layer addSublayer:circleLayer];
    }
}


@end
