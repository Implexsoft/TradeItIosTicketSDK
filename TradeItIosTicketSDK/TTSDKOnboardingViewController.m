//
//  TTSDKOnboardingViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/4/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKOnboardingViewController.h"
#import "TTSDKBrokerSelectViewController.h"
#import "TTSDKLoginViewController.h"
#import "TTSDKPrimaryButton.h"

@interface TTSDKOnboardingViewController () {
    NSArray * brokers;
}

@property (weak, nonatomic) IBOutlet UILabel * tradeItLabel;
@property (weak, nonatomic) IBOutlet TTSDKPrimaryButton *brokerSelectButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *brokerDetailsTopConstraint;
@property (weak, nonatomic) IBOutlet UIButton *preferredBrokerButton;

@end

@implementation TTSDKOnboardingViewController


#pragma mark Constants

static int kBulletContainerTag = 2;
static NSString * kLoginViewControllerIdentifier = @"LOGIN";


#pragma mark Orientation

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}


#pragma mark Initialization

-(void) viewDidLoad {
    [super viewDidLoad];

    brokers = self.ticket.brokerList;

    [self.brokerSelectButton activate];

    [self styleCustomDropdownButton: self.preferredBrokerButton];

    // iPhone 4s and earlier
    if ([self.utils isSmallScreen]) {
        self.brokerDetailsTopConstraint.constant = 10.0f;
    }

    self.currentSelection = @"Fidelity";

    for (UIView *view in self.view.subviews) {
        if (view.tag == kBulletContainerTag) {
            CAShapeLayer * circleLayer = [self.utils retrieveCircleGraphicWithSize:view.frame.size.width andColor: self.styles.activeColor];
            [view.layer addSublayer:circleLayer];
        }
    }

    NSMutableAttributedString * poweredBy = [[NSMutableAttributedString alloc]initWithString:@"powered by "];
    NSMutableAttributedString * logoString = [[NSMutableAttributedString alloc] initWithAttributedString:[self.utils logoStringLight]];
    [logoString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13.0f] range:NSMakeRange(0, 7)];
    [poweredBy appendAttributedString:logoString];
    [self.tradeItLabel setAttributedText:poweredBy];
}

-(void) styleCustomDropdownButton: (UIButton *)button {
    button.backgroundColor = [UIColor clearColor];
    button.layer.borderColor = self.styles.activeColor.CGColor;
    button.layer.borderWidth = 1.5f;
    button.layer.cornerRadius = button.frame.size.height / 2;
    [button setTitleColor:self.styles.primaryTextColor forState:UIControlStateNormal];

    UILabel * preferredBrokerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, button.frame.size.width / 2, 8)];
    preferredBrokerLabel.backgroundColor = [UIColor clearColor];
    preferredBrokerLabel.font = [UIFont systemFontOfSize:8.0f];
    preferredBrokerLabel.textColor = [UIColor clearColor]; // temporarily removing preferred broker
    preferredBrokerLabel.text = @"PREFERRED BROKER";

    [button.titleLabel addSubview:preferredBrokerLabel];

    button.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    preferredBrokerLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:preferredBrokerLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem: button.titleLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:preferredBrokerLabel attribute:NSLayoutAttributeTrailingMargin relatedBy:NSLayoutRelationEqual toItem: button attribute: NSLayoutAttributeTrailingMargin multiplier:1.0 constant:-30.0]];

    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect bounds = CGRectMake(preferredBrokerLabel.frame.size.width - 9, 0, 8, 8);
    CGFloat radius = bounds.size.width / 2;
    CGFloat a = radius * sqrt((CGFloat)3.0) / 2;
    CGFloat b = radius / 2;
    [path moveToPoint:CGPointMake(0, b)];
    [path addLineToPoint:CGPointMake(a, -radius)];
    [path addLineToPoint:CGPointMake(-a, -radius)];

    [path closePath];
    [path applyTransform:CGAffineTransformMakeTranslation(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    shapeLayer.path = path.CGPath;

    shapeLayer.strokeColor = self.styles.activeColor.CGColor;
    shapeLayer.fillColor = self.styles.activeColor.CGColor;

    [preferredBrokerLabel.layer addSublayer: shapeLayer];
}


#pragma mark Navigation

-(IBAction) brokerSelectPressed:(id)sender {
    [self selectBroker: self.currentSelection];
}

-(void)selectBroker:(NSString *)broker {
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];
    TTSDKLoginViewController * loginViewController = [ticket instantiateViewControllerWithIdentifier: kLoginViewControllerIdentifier];
    [loginViewController setAddBroker: broker];
    [self.navigationController pushViewController: loginViewController animated:YES];
}

- (IBAction)preferredBrokerPressed:(id)sender {
    if (!self.ticket.brokerList) {
        return;
    }

    NSMutableArray * optionsArray = [[NSMutableArray alloc] init];

    for (NSArray * broker in self.ticket.brokerList) {
        NSDictionary * brokerDict = @{broker[0]: broker[1]};
        [optionsArray addObject:brokerDict];
    }

    [self showPicker:@"Select account to trade with" withSelection:@"Fidelity" andOptions:[optionsArray copy] onSelection:^(void){
        [self.preferredBrokerButton setTitle:self.currentSelection forState:UIControlStateNormal];
    }];
}

-(IBAction) closePressed:(id)sender {
    [self.ticket returnToParentApp];
}


@end
