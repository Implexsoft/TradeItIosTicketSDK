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

@interface TTSDKOnboardingViewController ()

@property TTSDKUtils * utils;
@property (weak, nonatomic) IBOutlet UIButton * brokerSelectButton;
@property (weak, nonatomic) IBOutlet UILabel * tradeItLabel;

@end

@implementation TTSDKOnboardingViewController

static int kBulletContainerTag = 2;

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tradeSession = [TTSDKTicketSession globalSession];

    self.utils = [TTSDKUtils sharedUtils];

    for (UIView *view in self.view.subviews) {
        if (view.tag == kBulletContainerTag) {
            CAShapeLayer * circleLayer = [self.utils retrieveCircleGraphicWithSize:view.frame.size.width andColor:self.utils.activeButtonColor];
            [view.layer addSublayer:circleLayer];
        }
    }

    NSMutableAttributedString * poweredBy = [[NSMutableAttributedString alloc]initWithString:@"powered by "];
    NSMutableAttributedString * logoString = [[NSMutableAttributedString alloc] initWithAttributedString:[self.utils logoStringLight]];
    [logoString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13.0f] range:NSMakeRange(0, 7)];
    [poweredBy appendAttributedString:logoString];
    [self.tradeItLabel setAttributedText:poweredBy];

    [self.utils styleCustomDropdownButton:self.brokerSelectButton];
}

- (IBAction)closePressed:(id)sender {
    [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
}

#pragma mark - Navigation

- (IBAction)brokerSelectPressed:(id)sender {
    [self performSegueWithIdentifier:@"OnboardingToBrokerSelect" sender:self];
}


@end
