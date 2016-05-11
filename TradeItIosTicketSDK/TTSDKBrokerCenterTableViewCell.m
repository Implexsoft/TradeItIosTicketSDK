//
//  TTSDKBrokerCenterTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 5/9/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKBrokerCenterTableViewCell.h"

@interface TTSDKBrokerCenterTableViewCell()

@property TradeItBrokerCenterBroker * data;

@property (weak, nonatomic) IBOutlet UIView *bgView;
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
@property (weak, nonatomic) IBOutlet UILabel *featureSlot1;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot2;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot3;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot4;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot5;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot6;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot7;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot8;

@end

@implementation TTSDKBrokerCenterTableViewCell


-(void) configureWithBroker:(TradeItBrokerCenterBroker *)broker {
    self.data = broker;

    self.offerTitle.text = broker.signupTitle;
    self.offerDescription.text = broker.signupDescription;
    self.accountMinimum.text = broker.accountMinimum;
    self.optionsOffer.text = broker.optionsOffer;
    self.stocksEtfsOffer.text = broker.stocksEtfsOffer;

    [self.callToActionButton setTitle:@"Open an Account" forState:UIControlStateNormal];

    UIColor * backgroundColor = [TTSDKBrokerCenterTableViewCell colorFromArray: broker.backgroundColor];
    UIView * selectedBackgroundView = [[UIView alloc] init]; //
    selectedBackgroundView.backgroundColor = backgroundColor;
    self.selectedBackgroundView = selectedBackgroundView;
    self.contentView.backgroundColor = backgroundColor; //backgroundColor
    self.backgroundColor = backgroundColor;
    self.bgView.backgroundColor = backgroundColor;

    UIColor * textColor = [TTSDKBrokerCenterTableViewCell colorFromArray: broker.textColor];
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
    self.featuresTitle.textColor = textColor;
    self.featureSlot1.textColor = textColor;
    self.featureSlot2.textColor = textColor;
    self.featureSlot3.textColor = textColor;
    self.featureSlot4.textColor = textColor;
    self.featureSlot5.textColor = textColor;
    self.featureSlot6.textColor = textColor;
    self.featureSlot7.textColor = textColor;
    self.featureSlot8.textColor = textColor;

    UIColor * buttonBackgroundColor = [TTSDKBrokerCenterTableViewCell colorFromArray: broker.promptBackgroundColor];
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

-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    [UIView setAnimationsEnabled:NO];

    [super setSelected:NO animated:NO];
    
    UIColor * bgColor = [TTSDKBrokerCenterTableViewCell colorFromArray:self.data.backgroundColor];

    self.bgView.backgroundColor = bgColor;
    self.bgView.alpha = 1.0f;

    self.selectedBackgroundView.backgroundColor = bgColor;
    self.selectedBackgroundView.alpha = 1.0f;

    self.contentView.backgroundColor = bgColor;
    self.contentView.alpha = 1.0f;

    self.backgroundColor = bgColor;
    self.alpha = 1.0f;

    [UIView setAnimationsEnabled:YES];
    [CATransaction commit];
}

-(void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    [UIView setAnimationsEnabled:NO];

    [super setHighlighted:NO animated:NO];

    UIColor * bgColor = [TTSDKBrokerCenterTableViewCell colorFromArray:self.data.backgroundColor];

    self.bgView.backgroundColor = bgColor;
    self.bgView.alpha = 1.0f;

    self.selectedBackgroundView.backgroundColor = bgColor;
    self.selectedBackgroundView.alpha = 1.0f;

    self.contentView.backgroundColor = bgColor;
    self.contentView.alpha = 1.0f;

    self.backgroundColor = bgColor;
    self.alpha = 1.0f;

    [UIView setAnimationsEnabled:YES];
    [CATransaction commit];
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
