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
    
    NSArray * questionOptions;
    NSString * currentSelection;
    NSDictionary * currentAccount;
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
    [self performSelector:NSSelectorFromString([self actionToPerform]) withObject:nil afterDelay:0.5];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startSpin];
}

#pragma mark - Actions To Perform While Loading

- (void) sendLoginReviewRequest {
    /*[[self tradeSession] asyncAuthenticateAndReviewWithCompletionBlock:^(TradeItResult* result){
        loginReviewResult = result;
        [self loginReviewRequestRecieved: loginReviewResult];
    }];*/
    
    TradeItResult * result = [[self tradeSession] authenticateAndReview];
    [self loginReviewRequestRecieved:result];
}

- (void) loginReviewRequestRecieved: (TradeItResult *) result {
    self.lastResult = result;

    if([result isKindOfClass:[TradeItStockOrEtfTradeReviewResult class]]){
    //REVIEW
        [self setReviewResult:(TradeItStockOrEtfTradeReviewResult *) result];
        [self performSegueWithIdentifier: @"loadingToReviewSegue" sender: self];
    }
    else if([result isKindOfClass:[TradeItSecurityQuestionResult class]]){
    //SECURITY QUESTION
        TradeItSecurityQuestionResult *securityQuestionResult = (TradeItSecurityQuestionResult *) result;
        
        if(securityQuestionResult.securityQuestionOptions != nil && securityQuestionResult.securityQuestionOptions.count > 0 ){
        //MULTI
            questionOptions = securityQuestionResult.securityQuestionOptions;
            currentSelection = questionOptions[0];
            
            CustomIOSAlertView * alert = [[CustomIOSAlertView alloc]init];
            [alert setContainerView:[self createPickerView]];
            [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SEND",nil]];
            
            [alert setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
                if(buttonIndex == 0) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                } else {
                    [[self tradeSession] asyncAnswerSecurityQuestion:currentSelection andCompletionBlock:^(TradeItResult *result) {
                        [self loginReviewRequestRecieved:result];
                    }];
                }
            }];
            
            [alert show];
        }
    //TODO
        /*
        else if(securityQuestionResult.challengeImage !=nil){
            result = [tradeSession answerSecurityQuestion:@"tradingticket"];
            return processResult(tradeSession, result);
        }
         */
        else if(securityQuestionResult.securityQuestion != nil){
        //SINGLE
            UIAlertView * alert;
            alert = [[UIAlertView alloc] initWithTitle:@"Security Question" message:securityQuestionResult.securityQuestion delegate: self cancelButtonTitle:@"CANCEL" otherButtonTitles: @"SEND", nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            
            //not sure if we need the dispatch, without async calls??
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
            });
        }
    }
    else if([result isKindOfClass:[TradeItMultipleAccountResult class]]){
    //ACCOUNT SELECT
        TradeItMultipleAccountResult * multiAccountResult = (TradeItMultipleAccountResult* ) result;
        questionOptions = multiAccountResult.accountList;
        currentAccount = questionOptions[0];
        
        CustomIOSAlertView * alert = [[CustomIOSAlertView alloc]init];
        [alert setContainerView:[self createPickerView]];
        [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SEND",nil]];
        
        [alert setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
            if(buttonIndex == 0) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [[self tradeSession] asyncSelectAccount:currentAccount andCompletionBlock:^(TradeItResult *result) {
                    [self loginReviewRequestRecieved:result];
                }];
            }
        }];
        
        [alert show];
    }
    else if([result isKindOfClass:[TradeItErrorResult class]]){
        UIAlertView * alert;
        NSString * errorMessage = @"Could Not Complete Your Order";
        BOOL popToRoot = YES;
        TradeItErrorResult * error = (TradeItErrorResult *) result;
        
        if(error.errorFields.count > 0) {
            NSString * errorField = (NSString *) error.errorFields[0];
            if([errorField isEqualToString:@"authenticationInfo"]) {
                errorMessage = error.longMessages.count > 0 ? [error longMessages][0] : errorMessage;
                popToRoot = NO;
            } else {
                errorMessage = error.longMessages.count > 0 ? [error longMessages][0] : errorMessage;
            }
        }
        
        if(popToRoot) {
            [[self tradeSession] setPopToRoot:YES];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
        alert = [[UIAlertView alloc] initWithTitle:@"Could Not Complete Order" message:errorMessage delegate: self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    } else {
        UIAlertView * alert;
        alert = [[UIAlertView alloc] initWithTitle:@"Could Not Complete Order" message:@"TradeIt is temporarily unavailable. Please try again in a few minutes." delegate: self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        
        [alert show];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if([[self lastResult] isKindOfClass:[TradeItSecurityQuestionResult class]]) {
        if(buttonIndex == 1) {
            [[self tradeSession] asyncAnswerSecurityQuestion: [[alertView textFieldAtIndex:0] text] andCompletionBlock:^(TradeItResult *result) {
                [self loginReviewRequestRecieved:result];
            }];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - Review MultiSelects

- (UIView *)createPickerView {
    NSString * popupTitle;
    int tag;
    UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    if([self.lastResult isKindOfClass:[TradeItSecurityQuestionResult class]]) {
        TradeItSecurityQuestionResult * currentResult = (TradeItSecurityQuestionResult *) self.lastResult;
        popupTitle = currentResult.securityQuestion;
        tag = 501;
    } else {
        popupTitle = @"Please select an account:";
        tag = 502;
    }
    
    UILabel * question = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 270, 50)];
    [question setTextColor:[UIColor blackColor]];
    [question setTextAlignment:NSTextAlignmentCenter];
    [question setFont:[UIFont systemFontOfSize:12]];
    [question setText: popupTitle];
    [contentView addSubview:question];
    
    UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, 50, 270, 130)];
    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [picker setTag: tag];
    [contentView addSubview:picker];
    
    [contentView setNeedsDisplay];
    return contentView;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return questionOptions.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if([pickerView tag] == 501) {
        return questionOptions[row];
    } else {
        return [questionOptions[row] objectForKey:@"name"];
    }

}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if([pickerView tag] == 501) {
        currentSelection = questionOptions[row];
    } else {
        currentAccount = questionOptions[row];
    }
}

#pragma mark - Send Order

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

























