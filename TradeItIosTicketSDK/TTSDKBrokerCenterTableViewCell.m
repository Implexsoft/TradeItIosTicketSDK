//
//  TTSDKBrokerCenterTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 5/9/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKBrokerCenterTableViewCell.h"

@interface TTSDKBrokerCenterTableViewCell()

@property NSDictionary * data;

@property (weak, nonatomic) IBOutlet UIImageView *logo;
@property (weak, nonatomic) IBOutlet UILabel *offerTitle;
@property (weak, nonatomic) IBOutlet UILabel *offerDescription;
@property (weak, nonatomic) IBOutlet UILabel *accountMinimum;
@property (weak, nonatomic) IBOutlet UILabel *optionsOffer;
@property (weak, nonatomic) IBOutlet UILabel *stocksEtfsOffer;
@property (weak, nonatomic) IBOutlet UIButton *callToActionButton;
@property (weak, nonatomic) IBOutlet UIImageView *detailsArrow;
@property (weak, nonatomic) IBOutlet UILabel *optionsTitle;
@property (weak, nonatomic) IBOutlet UILabel *stocksEtfsTitle;
@property (weak, nonatomic) IBOutlet UILabel *featuresTitle;

@end

@implementation TTSDKBrokerCenterTableViewCell


-(void) configureWithData:(NSDictionary *)data {
    self.data = data;
//    NSString * path = [data valueForKey: @"logo"];
//    if (![path isEqualToString:@""]) {
//        NSURL *url = [NSURL URLWithString:path];
//        NSData * urlData = [NSData dataWithContentsOfURL:url];
//        UIImage *img = [[UIImage alloc] initWithData: urlData];
//        self.logo.image = img;
//
//        [self.logo.layer setMinificationFilter:kCAFilterTrilinear];
//    }

    self.offerTitle.text = [data valueForKey: @"offerTitle"];
    self.offerDescription.text = [data valueForKey: @"offerDescription"];
    self.accountMinimum.text = [data valueForKey: @"accountMinimum"];
    self.optionsOffer.text = [data valueForKey: @"optionsOffer"];
    self.stocksEtfsOffer.text = [data valueForKey: @"stocksEtfsOffer"];

    [self.callToActionButton setTitle:@"Open an Account" forState:UIControlStateNormal];

    UIColor * selectedBackgroundColor = (UIColor *)[data valueForKey:@"backgroundColor"];

    UIView * selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = selectedBackgroundColor;
    self.selectedBackgroundView = selectedBackgroundView;
    self.contentView.backgroundColor = selectedBackgroundColor;

    UIColor * textColor = (UIColor *)[data valueForKey:@"textColor"];

    self.offerTitle.textColor = textColor;
    self.offerDescription.textColor = textColor;
    self.accountMinimum.textColor = textColor;
    self.optionsOffer.textColor = textColor;
    self.optionsTitle.textColor = textColor;
    self.stocksEtfsOffer.textColor = textColor;
    self.stocksEtfsTitle.textColor = textColor;
    [self.callToActionButton setTitleColor:textColor forState:UIControlStateNormal];

    self.detailsArrow.image = [self.detailsArrow.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.detailsArrow.tintColor = textColor;

    UIColor * buttonBackgroundColor = (UIColor *)[data valueForKey:@"buttonBackgroundColor"];
    self.callToActionButton.backgroundColor = buttonBackgroundColor;
    self.callToActionButton.layer.cornerRadius = 5.0f;
}

-(void) setSelected:(BOOL)selected {
    UIColor * bgColor = (UIColor *)[self.data valueForKey:@"backgroundColor"];

    self.contentView.backgroundColor = bgColor;
//    self.backgroundColor = bgColor;
}

-(void) addImage:(UIImage *)img {
    if (img) {
        self.logo.image = img;
    }
}

-(void) configureSelectedState:(BOOL)selected {
    if (selected) {
        self.detailsArrow.hidden = YES;
    } else {
        self.detailsArrow.hidden = NO;
    }
}


@end
