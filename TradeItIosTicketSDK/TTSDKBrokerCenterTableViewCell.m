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

    self.offerTitle.text = [data valueForKey: @"signupTitle"];
    self.offerDescription.text = [data valueForKey: @"signupDescription"];
    self.accountMinimum.text = [data valueForKey: @"accountMinimum"];
    self.optionsOffer.text = [data valueForKey: @"optionsOffer"];
    self.stocksEtfsOffer.text = [data valueForKey: @"stocksEtfsOffer"];

    [self.callToActionButton setTitle:@"Open an Account" forState:UIControlStateNormal];

    UIColor * backgroundColor = [TTSDKBrokerCenterTableViewCell colorFromArray: [data valueForKey:@"backgroundColor"]];
    UIView * selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = backgroundColor;
    self.selectedBackgroundView = selectedBackgroundView;
    self.contentView.backgroundColor = backgroundColor;

    UIColor * textColor = [TTSDKBrokerCenterTableViewCell colorFromArray: [data valueForKey:@"textColor"]];
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

    UIColor * buttonBackgroundColor = [TTSDKBrokerCenterTableViewCell colorFromArray:[data valueForKey:@"buttonBackgroundColor"]];
    self.callToActionButton.backgroundColor = buttonBackgroundColor;
    self.callToActionButton.layer.cornerRadius = 5.0f;
}

+(UIColor *) colorFromArray:(NSArray *)colorArray {
    NSNumber * red = [colorArray objectAtIndex:0];
    NSNumber * green = [colorArray objectAtIndex:1];
    NSNumber * blue = [colorArray objectAtIndex:2];
    NSNumber * alpha;

    if (colorArray.count > 3) {
        alpha = [colorArray objectAtIndex:3];
    } else {
        alpha = @1.0;
    }

    UIColor * color = [UIColor colorWithRed: [red floatValue]/255.0f  green:[green floatValue]/255.0f blue:[blue floatValue]/255.0f alpha:[alpha floatValue]];

    return color;
}

-(void) setSelected:(BOOL)selected {
    UIColor * bgColor = [TTSDKBrokerCenterTableViewCell colorFromArray:[self.data valueForKey:@"backgroundColor"]];

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
