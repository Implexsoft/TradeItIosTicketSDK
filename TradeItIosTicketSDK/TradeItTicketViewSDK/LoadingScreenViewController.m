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
    } else if([[self actionToPerform] isEqualToString:@"verifyCredentials"]) {
        [indicatorText setText:@"Validating Your Credentials"];
    }
    
    //using a delay, o/w it complains about how perform selector might cause a leak
    [self performSelector:NSSelectorFromString([self actionToPerform]) withObject:nil afterDelay:0.5];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startSpin];
}

#pragma mark - Actions To Perform While Loading

- (void) verifyCredentials {
    TradeItVerifyCredentialSession * verifyCredsSession = [[TradeItVerifyCredentialSession alloc] initWithpublisherApp: self.tradeSession.publisherApp];
    TradeItResult * res = [verifyCredsSession verifyUser:self.tradeSession.authenticationInfo withBroker:self.tradeSession.broker];
    [self verifyCredentialsRequestRecieved: res];
}

-(void) verifyCredentialsRequestRecieved: (TradeItResult *) result {
    
    if([result isKindOfClass:[TradeItErrorResult class]]) {
        self.tradeSession.errorTitle = @"Connection Problem";
        self.tradeSession.errorMessage = @"We're experiencing some issues connecting to the authentication server. Please try again later.";

        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        TradeItSuccessAuthenticationResult * success = (TradeItSuccessAuthenticationResult *) result;
        
        if(success.credentialsValid) {
            [TradeItTicket storeUsername:self.tradeSession.authenticationInfo.id andPassword:self.tradeSession.authenticationInfo.password forBroker:self.tradeSession.broker];
            [TradeItTicket addLinkedBroker:self.tradeSession.broker];
            [self performSegueWithIdentifier:@"loginToCalculator" sender:self];
        } else {
            self.tradeSession.errorTitle = @"Invalid Credentials";
            self.tradeSession.errorMessage = @"Check your username and password and try again.";
            [self dismissViewControllerAnimated:YES completion:nil];
            
            //TODO remove previously linked creds
        }
    }
}

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
            [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SUBMIT",nil]];
            
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
            alert = [[UIAlertView alloc] initWithTitle:@"Security Question" message:securityQuestionResult.securityQuestion delegate: self cancelButtonTitle:@"CANCEL" otherButtonTitles: @"SUBMIT", nil];
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
        [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SUBMIT",nil]];
        
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
    if([self.lastResult isKindOfClass:[TradeItSecurityQuestionResult class]]) {
        return [self createSecurityPickerView];
    } else {
        return [self createAccountPickerView];
    }
}

- (UIView *)createAccountPickerView {
    UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 270, 50)];
    [title setTextColor:[UIColor blackColor]];
    [title setTextAlignment:NSTextAlignmentCenter];
    [title setFont: [UIFont boldSystemFontOfSize:16.0f]];
    [title setNumberOfLines:0];
    [title setText: @"Select the account\ryou want to trade in"];
    [contentView addSubview:title];
    
    UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, 50, 270, 130)];
    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [picker setTag: 502];
    [contentView addSubview:picker];
    
    [contentView setNeedsDisplay];
    return contentView;
}

- (UIView *)createSecurityPickerView {
    UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    TradeItSecurityQuestionResult * currentResult = (TradeItSecurityQuestionResult *) self.lastResult;
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 270, 20)];
    [title setTextColor:[UIColor blackColor]];
    [title setTextAlignment:NSTextAlignmentCenter];
    [title setFont: [UIFont boldSystemFontOfSize:16.0f]];
    [title setText: @"Verify Identity"];
    [contentView addSubview:title];
    
    UILabel * question = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, 270, 150)];
    [question setTextColor:[UIColor blackColor]];
    [question setTextAlignment:NSTextAlignmentCenter];
    [question setFont:[UIFont systemFontOfSize:12]];
    [question setNumberOfLines:0];
    [question setText: currentResult.securityQuestion];
    
    //resize to fit text
    CGSize requiredSize = [question sizeThatFits:CGSizeMake(270, 150)];
    CGRect questionFrame = question.frame;
    CGFloat questionHeight = questionFrame.size.height = requiredSize.height;
    question.frame = questionFrame;
    
    [contentView addSubview:question];
    
    //If the question is more than two lines, stretch it!
    if(questionHeight > 30) {
        CGRect contentFrame = contentView.frame;
        contentFrame.size.height = 250;
        contentView.frame = contentFrame;
    }
    
    UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, (20 + questionHeight), 270, (200 - 35 - questionHeight))];
    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [picker setTag: 501];
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
    } else if([segue.identifier isEqualToString:@"loginToCalculator"]) {
        UINavigationController * nav = (UINavigationController *)[segue destinationViewController];
        CalculatorViewController * initialViewController = [((UINavigationController *)nav).viewControllers objectAtIndex:0];
        [initialViewController setTradeSession: self.tradeSession];
    }
    
}


@end

























