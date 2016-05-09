//
//  BrokerSelectTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/2/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBrokerSelectTableViewCell.h"
#import "TradeItStyles.h"

@interface TTSDKBrokerSelectTableViewCell() {
    UIImageView * customDisclosureView;
    TradeItStyles * styles;
}

@end

@implementation TTSDKBrokerSelectTableViewCell


#pragma mark Constants

static float kDisclosureWidth = 7.0f;


#pragma mark Initialization

-(void) awakeFromNib {
    if (self) {
        styles = [TradeItStyles sharedStyles];

        self.textLabel.textColor = styles.primaryTextColor;

        self.backgroundColor = styles.pageBackgroundColor;

        UIImage * disclosureImage = [UIImage imageNamed:@"TradeItIosTicketSDK.bundle/native_arrow.png"];
        disclosureImage = [disclosureImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

        customDisclosureView = [[UIImageView alloc] initWithImage:disclosureImage];
        customDisclosureView.tintColor = styles.activeColor;
        customDisclosureView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:customDisclosureView];
    }
}

-(void) layoutSubviews {
    [super layoutSubviews];

    customDisclosureView.frame = CGRectMake(self.contentView.frame.size.width - (kDisclosureWidth * 3), 0, kDisclosureWidth, self.contentView.frame.size.height);
}

-(void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        self.textLabel.textColor = styles.primaryTextHighlightColor;
    } else {
        self.textLabel.textColor = styles.primaryTextColor;
    }
}

-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    if (selected) {
        self.textLabel.textColor = styles.primaryTextHighlightColor;
    } else {
        self.textLabel.textColor = styles.primaryTextColor;
    }
}


#pragma mark Configuration

-(void) configureCellWithText:(NSString *)text isOpenAccountCell:(BOOL)isOpenAccountCell {
    self.textLabel.text = text;

    if (isOpenAccountCell) {
        self.textLabel.textColor = styles.activeColor;
    }
}


@end
