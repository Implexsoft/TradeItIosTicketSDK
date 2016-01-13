//
//  TTSDKAccountLinkTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/13/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountLinkTableViewCell.h"

@interface TTSDKAccountLinkTableViewCell()

@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *toggle;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *buyingPowerLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *accountTypeLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *accountNameLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *circleGraphic;

@end

@implementation TTSDKAccountLinkTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
