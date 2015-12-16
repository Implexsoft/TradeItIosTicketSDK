//
//  TTSDKPortfolioTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/16/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioTableViewCell.h"

@implementation TTSDKPortfolioTableViewCell

- (void)awakeFromNib {
    // Initialization code
    if (self) {
        self.textLabel.textColor = [UIColor colorWithRed:65.0f/255.0f green:65.0f/255.0f blue:65.0f/255.0f alpha:1];
        self.contentView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.detailTextLabel.textColor = [UIColor colorWithRed:0.592 green:0.592 blue:0.592 alpha:1];
        
        self.indentationLevel = 6;
    }
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

- (void)configureCell {
    // set title
    self.textLabel.text = @"this is a title";

    // format creation date
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, yyyy"];

    // set subtitle to formatted string
    self.detailTextLabel.text = @"details!";

    [self insertAlertsDetailWithCount:1];
}

- (void)insertAlertsDetailWithCount:(int)count {
    CGFloat alertSize = 25;
    CGFloat alertTextSize = 14;
    
    struct CGColor *alertFill = [[UIColor clearColor] CGColor];
    
    CAShapeLayer *circleLayer;
    CATextLayer *countLayer;
    
    BOOL isNewLayer = YES;
    
    for (id item in self.contentView.layer.sublayers) {
        if ([NSStringFromClass([item class]) isEqualToString:@"CAShapeLayer"]) {
            circleLayer = item;
            isNewLayer = NO;
            
            for (id sub in circleLayer.sublayers) {
                if ([NSStringFromClass([sub class]) isEqualToString:@"CATextLayer"]) {
                    countLayer = sub;
                    break;
                }
            }
            
            break;
        }
    }
    
    if (!circleLayer) {
        circleLayer = [CAShapeLayer layer];
        [circleLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(alertTextSize, (self.frame.size.height / 2) - (alertSize / 2), alertSize, alertSize)] CGPath]];
        countLayer = [CATextLayer layer];
        countLayer.frame = CGRectMake(alertTextSize, ((self.frame.size.height / 2) - (alertSize / 2)) + (alertTextSize / 3), alertSize, alertSize);
        countLayer.foregroundColor = [[UIColor whiteColor] CGColor];
        countLayer.font = (__bridge CFTypeRef)([UIFont boldSystemFontOfSize:5]);
        countLayer.fontSize = alertTextSize;
        countLayer.alignmentMode = kCAAlignmentCenter;
        countLayer.contentsScale = [[UIScreen mainScreen] scale];
    }
    
    if (count == 0) {
        alertFill = [[UIColor colorWithRed:0.961 green:0.647 blue:0.137 alpha:0.25] CGColor];
    } else {
        alertFill = [[UIColor colorWithRed:0.961 green:0.647 blue:0.137 alpha:1] CGColor];
    }
    
    [circleLayer setFillColor: alertFill];
    countLayer.string = [NSString stringWithFormat:@"%i", count];
    
    if (isNewLayer) {
        [circleLayer addSublayer:countLayer];
        [self.contentView.layer addSublayer:circleLayer];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
