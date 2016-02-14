//
//  TTSDKAccountSelectTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/16/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountSelectTableViewCell.h"
#import "TTSDKTicketController.h"
#import "TTSDKUtils.h"

@interface TTSDKAccountSelectTableViewCell() {
    TTSDKUtils * utils;
    TTSDKTicketController * globalController;
}

@property (unsafe_unretained, nonatomic) IBOutlet UIView * circle;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel * brokerLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel * accountTypeLabel;

@end

@implementation TTSDKAccountSelectTableViewCell

- (void)awakeFromNib {
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

        utils = [TTSDKUtils sharedUtils];
        globalController = [TTSDKTicketController globalController];
    }
}

-(void) configureCellWithAccount:(NSDictionary *)account {
    self.brokerLabel.text = [account valueForKey: @"displayTitle"];
    self.brokerLabel.frame = CGRectMake(self.textLabel.frame.origin.x + 40, self.textLabel.frame.origin.y, self.brokerLabel.frame.size.width, self.textLabel.frame.size.height);

    // set subtitle to formatted string
    self.accountTypeLabel.text = @"Brokerage";
    
    [self insertPortfolioDetail:[account valueForKey:@"broker"]];
}

- (void)insertPortfolioDetail:(NSString *)broker {
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
