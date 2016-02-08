//
//  BaseCalculatorViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBaseTradeViewController.h"
#import "TTSDKTradeItTicket.h"

@implementation TTSDKBaseTradeViewController



static NSString * kLoginSegueIdentifier = @"TradeToLogin";



#pragma mark - Rotation

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

    self.globalController = [TTSDKTicketController globalController];
    self.utils = [TTSDKUtils sharedUtils];
}

-(void) checkIfAuthIsComplete {
    [self promptTouchId];
}

-(void) promptTouchId {
    LAContext * myContext = [[LAContext alloc] init];
    NSString * myLocalizedReasonString = @"Enable Broker Login to Trade";

    [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
              localizedReason:myLocalizedReasonString
                        reply:^(BOOL success, NSError *error) {
                            if (success) {

                                // TODO - set initial auth state

                            } else {
                                //too many tries, or cancelled by user
                                if(error.code == -2 || error.code == -1) {
                                    [self.globalController returnToParentApp];
                                } else if(error.code == -3) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self performSegueWithIdentifier:kLoginSegueIdentifier sender:self];
                                    });
                                }
                            }
                        }];
}



#pragma mark - order state

-(void) changeOrderAction: (NSString *) action {
    // Implement me in subclass
}

-(void) changeOrderExpiration: (NSString *) exp {
    // Implement me in subclass
}



#pragma mark - Custom views

-(UIView *) createPickerView: (NSString *) title {
    UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 270, 20)];
    [titleLabel setTextColor:[UIColor blackColor]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setFont: [UIFont boldSystemFontOfSize:16.0f]];
    [titleLabel setNumberOfLines:0];
    [titleLabel setText: title];
    [contentView addSubview:titleLabel];
    
    UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, 20, 270, 130)];
    self.currentPicker = picker;
    
    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [contentView addSubview:picker];
    
    [contentView setNeedsDisplay];
    return contentView;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pickerTitles.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.pickerTitles[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.currentSelection = self.pickerValues[row];
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

//    TradeItSecurityQuestionResult * currentResult = (TradeItSecurityQuestionResult *) self.lastResult;

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
//    [question setText: currentResult.securityQuestion];

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



#pragma mark - iOS7 fallbacks

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) showOldSecQuestion:(NSString *) question {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:@"Security Question" message:question delegate: self cancelButtonTitle:@"CANCEL" otherButtonTitles: @"SUBMIT", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

//-(void) showOldMultiSelect:(TradeItSecurityQuestionResult *) securityQuestionResult {
//    self.questionOptions = securityQuestionResult.securityQuestionOptions;
//    self.currentSelection = self.questionOptions[0];
//    
//    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
//    [alert setContainerView:[self createPickerView]];
//    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SUBMIT",nil]];
//    
//    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
//        if(buttonIndex == 0) {
//            [self dismissViewControllerAnimated:YES completion:nil];
//        } else {
//            [[self tradeSession] asyncAnswerSecurityQuestion:self.currentSelection andCompletionBlock:^(TradeItResult *result) {
//                [self loginReviewRequestRecieved:result];
//            }];
//        }
//    }];
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [alert show];
//    });
//}

-(void) showOldOrderAction {
    self.pickerTitles = @[@"Buy",@"Sell",@"Buy to Cover",@"Sell Short"];
    self.pickerValues = @[@"buy",@"sell",@"buyToCover",@"sellShort"];
    self.currentSelection = self.globalController.tradeRequest.orderAction;




    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Order Action"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 1) {
            [self changeOrderAction: self.currentSelection];
        }
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];

        if([self.globalController.tradeRequest.orderAction isEqualToString:@"sellShort"]){
            [self.currentPicker selectRow:3 inComponent:0 animated:NO];
        } else if([self.globalController.tradeRequest.orderAction isEqualToString:@"buyToCover"]){
            [self.currentPicker selectRow:2 inComponent:0 animated:NO];
        } else if([self.globalController.tradeRequest.orderAction isEqualToString:@"sell"]){
            [self.currentPicker selectRow:1 inComponent:0 animated:NO];
        }
    });
}

-(void) showOldOrderExp {
    self.pickerTitles = @[@"Good For The Day",@"Good Until Canceled"];
    self.pickerValues = @[@"day",@"gtc"];
    self.currentSelection = self.globalController.tradeRequest.orderExpiration;

    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Order Expiration"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];

    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 1) {
            [self changeOrderExpiration: self.currentSelection];
        }
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];

        if([self.globalController.tradeRequest.orderExpiration isEqualToString:@"gtc"]) {
            [self.currentPicker selectRow:1 inComponent:0 animated:NO];
        }
    });
}

-(void) sendReviewRequest {
    [self.globalController previewTrade:^(TradeItResult * res){
        if ([res isKindOfClass:TradeItPreviewTradeResult.class]) {
            self.globalController.resultContainer.status = USER_CANCELED;
            self.globalController.resultContainer.reviewResponse = (TradeItPreviewTradeResult *)res;

            [self performSegueWithIdentifier:@"TradeToReview" sender:self];
        } else if([res isKindOfClass:[TradeItErrorResult class]]){
            NSString * errorMessage = @"Could Not Complete Your Order";
            TradeItErrorResult * error = (TradeItErrorResult *)res;

            if(error.errorFields.count > 0) {
                NSString * errorField = (NSString *) error.errorFields[0];
                if([errorField isEqualToString:@"authenticationInfo"]) {
                    errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
    
                    self.globalController.resultContainer.status = AUTHENTICATION_ERROR;
                    self.globalController.resultContainer.errorResponse = error;
                } else {
                    errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
                }
            }

            if(![UIAlertController class]) {
                [self showOldErrorAlert:@"Could Not Complete Order" withMessage:errorMessage];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                                message:errorMessage
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {
                                                                           [self acknowledgeAlert];
                                                                       }];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
        } else {
            if(![UIAlertController class]) {
                [self showOldErrorAlert:@"Could Not Complete Order" withMessage:@"TradeIt is temporarily unavailable. Please try again in a few minutes."];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                                message:@"TradeIt is temporarily unavailable. Please try again in a few minutes."
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {
                                                                           [self acknowledgeAlert];
                                                                       }];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
    }];
}




-(void) acknowledgeAlert {
    // implement in sub class
}


@end
