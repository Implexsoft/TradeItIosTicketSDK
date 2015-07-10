//
//  LoadingScreenViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/24/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "LoadingScreenViewController.h"

@interface LoadingScreenViewController () {
    
    __weak IBOutlet UIImageView *loadingIcon;
    __weak IBOutlet UILabel *indicatorText;
    
    BOOL animating;
    
    TradeItResult * result;
}

@end

@implementation LoadingScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //TODO - Artificial Delay Until Callbacks are in place
    [self performSelector:NSSelectorFromString([self actionToPerform]) withObject:nil afterDelay:0.5];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startSpin];
}

#pragma mark - Actions To Perform While Loading

- (void) sendLoginReviewRequest {
    //TODO check for error o/w do it up!
    //result = [[self tradeSession] authenticateAndTrade];
    
    [self performSegueWithIdentifier: @"loadingToReviewSegue" sender: self];
}

- (void) sendTradeRequest {
    //TODO check for error o/w do it up!
    //result = [[self tradeSession] placeOrder];
    
    [self performSegueWithIdentifier: @"loadingToSuccesSegue" sender: self];
}

#pragma mark - Loading Animations

- (void) spinWithOptions: (UIViewAnimationOptions) options {
    // this spin completes 360 degrees every 2 seconds
    [UIView animateWithDuration: 0.5f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         loadingIcon.transform = CGAffineTransformRotate(loadingIcon.transform, M_PI / 2);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if (animating) {
                                 // if flag still set, keep spinning with constant speed
                                 [self spinWithOptions: UIViewAnimationOptionCurveLinear];
                             } else if (options != UIViewAnimationOptionCurveEaseOut) {
                                 // one last spin, with deceleration
                                 [self spinWithOptions: UIViewAnimationOptionCurveEaseOut];
                             }
                         }
                     }];
}

- (void) startSpin {
    if (!animating) {
        animating = YES;
        [self spinWithOptions: UIViewAnimationOptionCurveEaseIn];
    }
}

- (void) stopSpin {
    // set the flag to stop spinning after one last 90 degree increment
    animating = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    //if([segue.identifier isEqualToString:@"loadingToReviewSegue"]) {
        //UINavigationController * dest = (UINavigationController *)[segue destinationViewController];
        //ReviewScreenViewController * rootController=(ReviewScreenViewController *)[dest.viewControllers objectAtIndex:0];
        
        //[rootController setTradeSession: self.tradeSession];
        //[rootController setResult: result];
    //} else {
        //[[segue destinationViewController] setResult: result];
        //[[segue destinationViewController] setTradeSession: self.tradeSession];
    //}
    
}


@end


























