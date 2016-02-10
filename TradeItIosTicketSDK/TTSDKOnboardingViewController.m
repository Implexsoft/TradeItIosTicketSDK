//
//  TTSDKOnboardingViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/4/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKOnboardingViewController.h"
#import "TTSDKBrokerSelectViewController.h"
#import "TTSDKUtils.h"

@interface TTSDKOnboardingViewController () {
    TTSDKUtils * utils;
}

@property (weak, nonatomic) IBOutlet UIButton * brokerSelectButton;
@property (weak, nonatomic) IBOutlet UILabel * tradeItLabel;

@end

@implementation TTSDKOnboardingViewController



#pragma mark - Constants

static int kBulletContainerTag = 2;



#pragma mark - Orientation

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}



#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];

    utils = [TTSDKUtils sharedUtils];

    for (UIView *view in self.view.subviews) {
        if (view.tag == kBulletContainerTag) {
            CAShapeLayer * circleLayer = [utils retrieveCircleGraphicWithSize:view.frame.size.width andColor:utils.activeButtonColor];
            [view.layer addSublayer:circleLayer];
        }
    }

    NSMutableAttributedString * poweredBy = [[NSMutableAttributedString alloc]initWithString:@"powered by "];
    NSMutableAttributedString * logoString = [[NSMutableAttributedString alloc] initWithAttributedString:[utils logoStringLight]];
    [logoString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13.0f] range:NSMakeRange(0, 7)];
    [poweredBy appendAttributedString:logoString];
    [self.tradeItLabel setAttributedText:poweredBy];

    [utils styleCustomDropdownButton:self.brokerSelectButton];
}



#pragma mark - Navigation

- (IBAction)brokerSelectPressed:(id)sender {
    [self performSegueWithIdentifier:@"OnboardingToBrokerSelect" sender:self];
}

- (IBAction)closePressed:(id)sender {
    [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
}



@end
