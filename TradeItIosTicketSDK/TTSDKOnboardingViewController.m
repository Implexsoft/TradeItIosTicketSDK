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
#import "TTSDKBrokerCenterViewController.h"

@interface TTSDKOnboardingViewController () {
    NSArray * brokers;
}

@property (weak, nonatomic) IBOutlet UILabel * tradeItLabel;
@property (weak, nonatomic) IBOutlet TTSDKPrimaryButton *brokerSelectButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *brokerDetailsTopConstraint;
@property (weak, nonatomic) IBOutlet UIButton *preferredBrokerButton;
@property (weak, nonatomic) IBOutlet UIButton *openAccountButton;

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

    if (!brokers || !self.ticket.adService.brokerCenterLoaded) {
        [self showLoadingAndWait];
    } else {
        if (self.ticket.adService.brokerCenterActive) {
            self.openAccountButton.hidden = NO;
        } else {
            self.openAccountButton.hidden = YES;
        }
    }
}

-(void) showLoadingAndWait {
    [TTSDKMBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        int cycles = 0;

        while(([self.ticket.brokerList count] < 1 || !self.ticket.adService.brokerCenterLoaded) && cycles < 15) {
            sleep(1);
            cycles++;
        }

        // We want to hide the broker center button if we either can't get the data or the broker center is disabled
        //you can use any string instead "com.mycompany.myqueue"
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.ticket.adService.brokerCenterLoaded && self.ticket.adService.brokerCenterActive) {
                self.openAccountButton.hidden = NO;
            } else {
                self.openAccountButton.hidden = YES;
            }
        });

        if([self.ticket.brokerList count] < 1) {
            if(![UIAlertController class]) {
                [self showOldErrorAlert:@"An Error Has Occurred" withMessage:@"TradeIt is temporarily unavailable. Please try again in a few minutes."];
                return;
            }

            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"An Error Has Occurred"
                                                                            message:@"TradeIt is temporarily unavailable. Please try again in a few minutes."
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            alert.modalPresentationStyle = UIModalPresentationPopover;
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       [self.ticket returnToParentApp];
                                                                   }];
            [alert addAction:defaultAction];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [TTSDKMBProgressHUD hideHUDForView:self.view animated:YES];
                [self presentViewController:alert animated:YES completion:nil];
                
                UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
                alertPresentationController.sourceView = self.view;
                alertPresentationController.permittedArrowDirections = 0;
                alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
            });
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                brokers = self.ticket.brokerList;
                
                [TTSDKMBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }
    });
}

-(void) styleCustomDropdownButton: (UIButton *)button {
    button.backgroundColor = [UIColor clearColor];
    button.layer.borderColor = self.styles.activeColor.CGColor;
    button.layer.borderWidth = 1.5f;
    button.layer.cornerRadius = 5.0f;
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

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"onboardingToBrokerCenter"]) {
        UINavigationController * nav = (UINavigationController *)segue.destinationViewController;

        TTSDKBrokerCenterViewController * dest = (TTSDKBrokerCenterViewController *)[nav.viewControllers objectAtIndex:0];
        dest.isModal = YES;
    }
}

- (IBAction)openAccountPressed:(id)sender {
    [self performSegueWithIdentifier:@"onboardingToBrokerCenter" sender:self];
}

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
        dispatch_async(dispatch_get_main_queue(), ^{
            [self populateBrokerButton];
        });
    }];
}

-(void) populateBrokerButton {
    [UIView setAnimationsEnabled:NO];
    [self.preferredBrokerButton setTitle:self.currentSelection forState:UIControlStateNormal];
    [UIView setAnimationsEnabled:YES];
}

-(IBAction) closePressed:(id)sender {
    [self.ticket returnToParentApp];
}


@end
