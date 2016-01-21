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
@property (weak, nonatomic) IBOutlet UIButton *brokerSelectButton;

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
