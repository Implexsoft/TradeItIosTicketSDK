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
}

@end

@implementation LoadingScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if([[self actionToPerform] isEqualToString:@"sendTradeRequest"]) {
        [indicatorText setText:@"Submitting Your Order"];
    }
    
    //using a delay, o/w it complains about how perform selector might cause a leak
    [self performSelector:NSSelectorFromString([self actionToPerform]) withObject:nil afterDelay:0.0];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startSpin];
}

#pragma mark - Actions To Perform While Loading

- (void) sendLoginReviewRequest {
    [[self tradeSession] asyncAuthenticateAndReviewWithCompletionBlock:^(TradeItResult* result){
        [self loginReviewRequestRecieved:result];
    }];
}

- (void) loginReviewRequestRecieved: (TradeItResult *) result {
    UIAlertView * error;
    
    error = [[UIAlertView alloc] initWithTitle:@"Could Not Complete Order" message:@"TradeIt is temporarily unavailable. Please try again in a few minutes." delegate: self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [error show];
    
    [self.navigationController popViewControllerAnimated:YES];
    
    return;
    if(result == nil){
        error = [[UIAlertView alloc] initWithTitle:@"Could Not Complete Order" message:@"TradeIt is temporarily unavailable. Please try again in a few minutes." delegate: self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    }
    else if([result isKindOfClass:[TradeItStockOrEtfTradeReviewResult class]]){
        //process review result
        [self setReviewResult:(TradeItStockOrEtfTradeReviewResult *) result];
        [self performSegueWithIdentifier: @"loadingToReviewSegue" sender: self];
    }
    else if([result isKindOfClass:[TradeItSecurityQuestionResult class]]){
        //process security question
        //TODO
        TradeItSecurityQuestionResult *securityQuestionResult = (TradeItSecurityQuestionResult *) result;
        NSLog(@"Received security result: %@", securityQuestionResult);
        
        /*
        if(securityQuestionResult.securityQuestionOptions != nil && securityQuestionResult.securityQuestionOptions.count > 0 ){
            result = [tradeSession answerSecurityQuestion:@"option 1" ];
            return processResult(tradeSession, result);
        }
        else if(securityQuestionResult.challengeImage !=nil){
            result = [tradeSession answerSecurityQuestion:@"tradingticket"];
            return processResult(tradeSession, result);
        }
        else if(securityQuestionResult.securityQuestion != nil){
            //answer security question
            result = [tradeSession answerSecurityQuestion:@"tradingticket" ];
            return processResult(tradeSession, result);
        }
         */
    }
    else if([result isKindOfClass:[TradeItMultipleAccountResult class]]){
        //TODO
        //process mutli account
        //cast result
        TradeItMultipleAccountResult * multiAccountResult = (TradeItMultipleAccountResult* ) result;
        NSLog(@"Received TradeItMultipleAccountResult result: %@", multiAccountResult);
        //result = [tradeSession selectAccount:multiAccountResult.accountList[0]];
        //return processResult(tradeSession, result);
        
    }
    else if([result isKindOfClass:[TradeItErrorResult class]]){
        //Received an error
        //TODO
        NSLog(@"Bummer!!!!, Received Error result: %@", result);
    }
    //TODO - else - throw random error
}

- (void) sendTradeRequest {
    //TODO - the async is breaking here for some reason.
    
    /*[[self tradeSession] asyncPlaceOrderWithCompletionBlock:^(TradeItResult *result) {
        [self tradeRequestRecieved:result];
    }];*/
    
    TradeItResult * result = [[self tradeSession] placeOrder];
    [self tradeRequestRecieved: result];
}

- (void) tradeRequestRecieved: (TradeItResult *) result {
    //success
    if([result isKindOfClass:[TradeItStockOrEtfTradeSuccessResult class]]){
        [self setSuccessResult:(TradeItStockOrEtfTradeSuccessResult *) result];
        [self performSegueWithIdentifier: @"loadingToSuccesSegue" sender: self];
    }
    //error
    else if([result isKindOfClass:[TradeItErrorResult class]]) {
        //Received an error
        //TODO
        NSLog(@"Bummer!!!!, Received Error result: %@", result);
    }
    //TODO - else - throw random error
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
    
    if([segue.identifier isEqualToString:@"loadingToReviewSegue"]) {
        UINavigationController * dest = (UINavigationController *)[segue destinationViewController];
        ReviewScreenViewController * rootController=(ReviewScreenViewController *)[dest.viewControllers objectAtIndex:0];
        
        [rootController setTradeSession: self.tradeSession];
        [rootController setResult: self.reviewResult];
    } else if([segue.identifier isEqualToString:@"loadingToSuccesSegue"]) {
        SuccessViewController * successPage = (SuccessViewController *)[segue destinationViewController];
        [successPage setResult: self.successResult];
        [successPage setTradeSession: self.tradeSession];
    }
    
}


@end


























