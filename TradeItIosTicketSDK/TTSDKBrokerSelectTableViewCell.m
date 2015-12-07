//
//  BrokerSelectTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/2/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBrokerSelectTableViewCell.h"

@implementation TTSDKBrokerSelectTableViewCell


- (void)awakeFromNib {
    if (self) {
        self.textLabel.textColor = [UIColor blackColor];
    }
}


- (UIEdgeInsets)layoutMargins {
    return UIEdgeInsetsZero;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);

//    UIImageView *customDisclosureView = [[ alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 30, 0, 30, self.contentView.frame.size.height)];
//    customDisclosureView.backgroundColor = [UIColor greenColor];

    UIImageView *customDisclosureView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TradeItIosTicketSDK.bundle/nativeArrow.png"]];

    customDisclosureView.contentMode = UIViewContentModeScaleAspectFit;

    customDisclosureView.frame = CGRectMake(self.contentView.frame.size.width - 7, 0, 7, self.contentView.frame.size.height);

    [self addSubview:customDisclosureView];
}


- (void)configureCell {
    //Maybe someday we can add these back
    //UIImage * logo = [UIImage imageNamed: [NSString stringWithFormat: @"TradeItIosTicketSDK.bundle/%@.png", valueText]];
    //UIImage * myIcon = [TradeItTicket imageWithImage:logo scaledToWidth: 50.0f withInset: 15.0f];
    //cell.imageView.image = myIcon;

//    self.textLabel.textColor = [UIColor colorWithRed:255.0f/255.0f green:65.0f/255.0f blue:65.0f/255.0f alpha:1];
//    [self setSeparatorInset:UIEdgeInsetsZero];

}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        self.backgroundColor = [UIColor grayColor];
    } else {
        self.backgroundColor = [UIColor whiteColor];
    }
}

- (void)setFrame:(CGRect)frame {
    int inset = 20;
    frame.origin.x += inset;
    frame.size.width -= inset * 2;

    [super setFrame:frame];
}

@end
