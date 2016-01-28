//
//  BrokerSelectTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/2/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBrokerSelectTableViewCell.h"

@interface TTSDKBrokerSelectTableViewCell() {
    UIImageView * customDisclosureView;
}

@end

@implementation TTSDKBrokerSelectTableViewCell

static float kDisclosureWidth = 7.0f;

- (void)awakeFromNib {
    if (self) {
        self.textLabel.textColor = [UIColor blackColor];

        customDisclosureView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TradeItIosTicketSDK.bundle/nativeArrow.png"]];
        customDisclosureView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:customDisclosureView];
    }
}

- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.textLabel.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
    customDisclosureView.frame = CGRectMake(self.contentView.frame.size.width - (kDisclosureWidth * 2), 0, kDisclosureWidth, self.contentView.frame.size.height);
}

- (void)configureCellWithText:(NSString *)text {
    self.textLabel.text = text;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        self.textLabel.textColor = [UIColor colorWithRed:180.0f/225.0f green:180.0f/225.0f blue:180.0f/225.0f alpha:1.0f];
    } else {
        self.textLabel.textColor = [UIColor blackColor];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if (selected) {
        self.textLabel.textColor = [UIColor colorWithRed:180.0f/225.0f green:180.0f/225.0f blue:180.0f/225.0f alpha:1.0f];
    } else {
        self.textLabel.textColor = [UIColor blackColor];
    }
}

- (void)setFrame:(CGRect)frame {
    int inset = 20;
    frame.origin.x += inset;
    frame.size.width -= inset * 2;

    [super setFrame:frame];
}


@end
