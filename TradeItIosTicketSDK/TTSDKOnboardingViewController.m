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
#import "TTSDKTicketController.h"
#import "TTSDKUtils.h"

@interface TTSDKOnboardingViewController () {
    TTSDKUtils * utils;
    TTSDKTicketController * globalController;
    NSArray * brokers;
}

@property (weak, nonatomic) IBOutlet UILabel * tradeItLabel;
@property (weak, nonatomic) IBOutlet UIButton *fidelityButton;
@property (weak, nonatomic) IBOutlet UIButton *brokerSelectButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *brokerDetailsTopConstraint;

@end

@implementation TTSDKOnboardingViewController



#pragma mark - Constants

static int kBulletContainerTag = 2;
static NSString * kLoginViewControllerIdentifier = @"LOGIN";



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
    globalController = [TTSDKTicketController globalController];

    brokers = globalController.brokerList;

    [utils styleMainActiveButton: self.brokerSelectButton];
    [self styleCustomDropdownButton: self.fidelityButton];

    // iPhone 4s and earlier
    if ([utils isSmallScreen]) {
        self.brokerDetailsTopConstraint.constant = 10.0f;
    }

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
}

-(void) styleCustomDropdownButton: (UIButton *)button {
    button.backgroundColor = [UIColor whiteColor];
    button.layer.borderColor = utils.activeButtonColor.CGColor;
    button.layer.borderWidth = 1.5f;
    button.layer.cornerRadius = button.frame.size.height / 2;
    [button setTitleColor:[UIColor colorWithRed:20.0f/255.0f green:20.0f/255.0f blue:20.0f/255.0f alpha:1.0] forState:UIControlStateNormal];

    UILabel * preferredBrokerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, button.frame.size.width / 2, 8)];
    preferredBrokerLabel.backgroundColor = [UIColor clearColor];
    preferredBrokerLabel.font = [UIFont systemFontOfSize:8.0f];
    preferredBrokerLabel.textColor = [UIColor lightGrayColor];
    preferredBrokerLabel.text = @"PREFERRED BROKER";

    [button.titleLabel addSubview:preferredBrokerLabel];

    button.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    preferredBrokerLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:preferredBrokerLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem: button.titleLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:preferredBrokerLabel attribute:NSLayoutAttributeLeadingMargin relatedBy:NSLayoutRelationEqual toItem: button.titleLabel attribute: NSLayoutAttributeTrailingMargin multiplier:1.0 constant:20.0]];

    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect bounds = CGRectMake(preferredBrokerLabel.frame.size.width - 8, 0, 8, 8);
    CGFloat radius = bounds.size.width / 2;
    CGFloat a = radius * sqrt((CGFloat)3.0) / 2;
    CGFloat b = radius / 2;
    [path moveToPoint:CGPointMake(0, b)];
    [path addLineToPoint:CGPointMake(a, -radius)];
    [path addLineToPoint:CGPointMake(-a, -radius)];

    [path closePath];
    [path applyTransform:CGAffineTransformMakeTranslation(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    shapeLayer.path = path.CGPath;

    shapeLayer.strokeColor = utils.activeButtonColor.CGColor;
    shapeLayer.fillColor = utils.activeButtonColor.CGColor;

    [preferredBrokerLabel.layer addSublayer: shapeLayer];
}

#pragma mark - Navigation

-(IBAction) brokerSelectPressed:(id)sender {
    [self performSegueWithIdentifier:@"OnboardingToBrokerSelect" sender:self];
}

-(IBAction) fidelityButtonPressed:(id)sender {
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];
    TTSDKLoginViewController * loginViewController = [ticket instantiateViewControllerWithIdentifier: kLoginViewControllerIdentifier];

    NSString * selectedBroker = [globalController getBrokerByValueString: @"Fidelity"][1];
    [loginViewController setAddBroker: selectedBroker];

    [self.navigationController pushViewController: loginViewController animated:YES];
}

-(IBAction) closePressed:(id)sender {
    [globalController returnToParentApp];
}



@end
