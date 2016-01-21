//
//  BaseCalculatorViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBaseTradeViewController.h"
#import "TTSDKTradeItTicket.h"

@interface TTSDKBaseTradeViewController () {
    NSArray * linkedBrokers;
    NSString * segueToLogin;
    NSString * selectedBroker;
}

@end

@implementation TTSDKBaseTradeViewController

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    linkedBrokers = [TTSDKTradeItTicket getLinkedBrokersList];

    self.tradeSession = [TTSDKTicketSession globalSession];

    segueToLogin = @"TradeToLogin";
}

-(void) promptTouchId {
    LAContext * myContext = [[LAContext alloc] init];
    NSString * myLocalizedReasonString = @"Enable Broker Login to Trade";
    
    [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
              localizedReason:myLocalizedReasonString
                        reply:^(BOOL success, NSError *error) {
                            if (success) {
                                if([[TTSDKTradeItTicket getLinkedBrokersList] count] > 1) {
                                    [self showBrokerPickerAndSetPassword:YES onSelection:nil];
                                } else {
                                    NSString * broker = [[TTSDKTradeItTicket getLinkedBrokersList] objectAtIndex:0];
                                    [self setAuthentication:broker withPassword:YES];
                                }
                            } else {
                                //too many tries, or cancelled by user
                                if(error.code == -2 || error.code == -1) {
                                    [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
                                } else if(error.code == -3) {
                                    //fallback mechanism selected
                                    //load username into creds
                                    //segue to login screen for the password
                                    
                                    if([[TTSDKTradeItTicket getLinkedBrokersList] count] > 1) {
                                        [self showBrokerPickerAndSetPassword:NO onSelection:^{
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self performSegueWithIdentifier:segueToLogin sender:self];
                                            });
                                        }];
                                    } else {
                                        NSString * broker = [[TTSDKTradeItTicket getLinkedBrokersList] objectAtIndex:0];
                                        [self setAuthentication:broker withPassword:NO];
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self performSegueWithIdentifier:segueToLogin sender:self];
                                        });
                                    }
                                    
                                }
                            }
                        }];
} //end promptTouchId

-(void) showBrokerPickerAndSetPassword:(BOOL) setPassword onSelection:(void (^)(void)) onSelection {
    if(![UIAlertController class]) {
        [self oldShowBrokerPickerAndSetPassword:setPassword onSelection:onSelection];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Broker"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (NSString * broker in linkedBrokers) {
            UIAlertAction * brokerOption = [UIAlertAction actionWithTitle: [TTSDKTradeItTicket getBrokerDisplayString:broker] style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      
                                                                      [self setAuthentication:broker withPassword:setPassword];
                                                                      
                                                                      if(onSelection) {
                                                                          onSelection();
                                                                      }
                                                                  }];
            [alert addAction:brokerOption];
        }
        
        UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
        }];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:YES completion:nil];
    });
}


#pragma mark - order state

-(void) setBroker {
    if (![self.tradeSession.authenticationInfo.id isEqualToString:@""] && [TTSDKTradeItTicket hasTouchId]) {
        //        [self promptTouchId];
    } else if([self.tradeSession.authenticationInfo.id isEqualToString:@""]){
        if([linkedBrokers count] > 1) {
            [self showBrokerPickerAndSetPassword:NO onSelection:^{
                [self performSegueWithIdentifier:segueToLogin sender:self];
            }];
        } else if (![linkedBrokers count]) {
            return;
        } else {
            [self setAuthentication:linkedBrokers[0] withPassword:NO];
            [self performSegueWithIdentifier:segueToLogin sender:self];
        }
    }
}

-(void) setAuthentication: (NSString *) broker withPassword: (BOOL) setPassword {
    self.tradeSession.broker = broker;
    TradeItAuthenticationInfo * creds = [TTSDKTradeItTicket getStoredAuthenticationForBroker: broker];
    
    if(setPassword) {
        self.tradeSession.authenticationInfo = creds;
    } else {
        self.tradeSession.authenticationInfo.id = creds.id;
    }
}

-(void) changeOrderAction: (NSString *) action {
    // Implement me in subclass
}

-(void) changeOrderExpiration: (NSString *) exp {
    // Implement me in subclass
}



#pragma mark - Custom views

- (UIView *)createPickerView {
    if([self.lastResult isKindOfClass:[TradeItSecurityQuestionResult class]]) {
        return [self createSecurityPickerView];
    } else {
        return [self createAccountPickerView];
    }
}

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



#pragma mark - iOS7 fallbacks

-(void) oldShowBrokerPickerAndSetPassword:(BOOL) setPassword onSelection:(void (^)(void)) onSelection {
    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];

    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 0) {
            [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
        } else {
             [self setAuthentication:selectedBroker withPassword:setPassword];

             if(onSelection) {
                onSelection();
             }
        }
    }];

    selectedBroker = linkedBrokers[0];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];

        int count = 0;
        for (NSString * broker in linkedBrokers) {
            if([broker isEqualToString:self.tradeSession.broker]) {
                [self.currentPicker selectRow:count inComponent:0 animated:NO];
            }

            count++;
        }
    });
}

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) showOldAcctSelect: (TradeItMultipleAccountResult *) multiAccountResult {
    self.questionOptions = multiAccountResult.accountList;
    self.currentAccount = self.questionOptions[0];

    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 0) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [[self tradeSession] asyncSelectAccount:self.currentAccount andCompletionBlock:^(TradeItResult *result) {
                [self loginReviewRequestRecieved:result];
            }];
        }
    }];
    
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

-(void) showOldMultiSelect:(TradeItSecurityQuestionResult *) securityQuestionResult {
    self.questionOptions = securityQuestionResult.securityQuestionOptions;
    self.currentSelection = self.questionOptions[0];
    
    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SUBMIT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 0) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [[self tradeSession] asyncAnswerSecurityQuestion:self.currentSelection andCompletionBlock:^(TradeItResult *result) {
                [self loginReviewRequestRecieved:result];
            }];
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) showOldOrderAction {
    self.pickerTitles = @[@"Buy",@"Sell",@"Buy to Cover",@"Sell Short"];
    self.pickerValues = @[@"buy",@"sell",@"buyToCover",@"sellShort"];
    self.currentSelection = self.tradeSession.orderInfo.action;
    
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
        
        if([self.tradeSession.orderInfo.action isEqualToString:@"sellShort"]){
            [self.currentPicker selectRow:3 inComponent:0 animated:NO];
        } else if([self.tradeSession.orderInfo.action isEqualToString:@"buyToCover"]){
            [self.currentPicker selectRow:2 inComponent:0 animated:NO];
        } else if([self.tradeSession.orderInfo.action isEqualToString:@"sell"]){
            [self.currentPicker selectRow:1 inComponent:0 animated:NO];
        }
    });
}

-(void) showOldOrderExp {
    self.pickerTitles = @[@"Good For The Day",@"Good Until Canceled"];
    self.pickerValues = @[@"day",@"gtc"];
    self.currentSelection = self.tradeSession.orderInfo.expiration;
    
    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Order Action"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 1) {
            [self changeOrderExpiration: self.currentSelection];
        }
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];

        if([self.tradeSession.orderInfo.expiration isEqualToString:@"gtc"]) {
            [self.currentPicker selectRow:1 inComponent:0 animated:NO];
        }
    });
}

-(void) sendLoginReviewRequest {
    [[self tradeSession] asyncAuthenticateAndReviewWithCompletionBlock:^(TradeItResult* result){
        [self loginReviewRequestRecieved: result];
    }];
}

-(void) loginReviewRequestRecieved: (TradeItResult *) result {
    self.lastResult = result;
    
    if ([result isKindOfClass:[TradeItStockOrEtfTradeReviewResult class]]){
        //REVIEW
        self.tradeSession.resultContainer.status = USER_CANCELED;
        self.tradeSession.resultContainer.reviewResponse = (TradeItStockOrEtfTradeReviewResult *) result;
        
        [self setReviewResult:(TradeItStockOrEtfTradeReviewResult *) result];
        [self performSegueWithIdentifier: @"TradeToReview" sender: self];
    }
    else if ([result isKindOfClass:[TradeItSecurityQuestionResult class]]){
        self.tradeSession.resultContainer.status = USER_CANCELED_SECURITY;
        
        //SECURITY QUESTION
        TradeItSecurityQuestionResult *securityQuestionResult = (TradeItSecurityQuestionResult *) result;
        
        if (securityQuestionResult.securityQuestionOptions != nil && securityQuestionResult.securityQuestionOptions.count > 0 ){
            //MULTI
            if(![UIAlertController class]) {
                [self showOldMultiSelect:securityQuestionResult];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Verify Identity"
                                                                                message:securityQuestionResult.securityQuestion
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                
                for(NSString * title in securityQuestionResult.securityQuestionOptions){
                    UIAlertAction * option = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction * action) {
                                                                        [[self tradeSession] asyncAnswerSecurityQuestion:title andCompletionBlock:^(TradeItResult *result) {
                                                                            // [self loginReviewRequestRecieved:result];
                                                                        }];
                                                                    }];
                    [alert addAction:option];
                }
                
                UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          // [self dismissViewControllerAnimated:YES completion:nil];
                                                                      }];
                [alert addAction:cancelAction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentViewController:alert animated:YES completion:nil];
                }) ;
            }
        } else if (securityQuestionResult.securityQuestion != nil){
            //SINGLE
            if(![UIAlertController class]) {
                [self showOldSecQuestion: securityQuestionResult.securityQuestion];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Security Question"
                                                                                message:securityQuestionResult.securityQuestion
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          [self dismissViewControllerAnimated:YES completion:nil];
                                                                      }];
                UIAlertAction * submitAction = [UIAlertAction actionWithTitle:@"SUBMIT" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          [[self tradeSession] asyncAnswerSecurityQuestion: [[alert textFields][0] text] andCompletionBlock:^(TradeItResult *result) { [self loginReviewRequestRecieved:result]; }];
                                                                      }];
                
                [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {}];
                [alert addAction:cancelAction];
                [alert addAction:submitAction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentViewController:alert animated:YES completion:nil];
                });
            }
        }
    } else if([result isKindOfClass:[TradeItMultipleAccountResult class]]){
        //ACCOUNT SELECT
        TradeItMultipleAccountResult * multiAccountResult = (TradeItMultipleAccountResult* ) result;
        
        if(![UIAlertController class]) {
            [self showOldAcctSelect: multiAccountResult];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Account"
                                                                            message:nil
                                                                     preferredStyle:UIAlertControllerStyleActionSheet];
            
            void (^handler)(NSDictionary * account) = ^(NSDictionary * account){
                [[self tradeSession] asyncSelectAccount:account andCompletionBlock:^(TradeItResult *result) {
                    [self loginReviewRequestRecieved:result];
                }];
            };
            
            for (NSDictionary * account in multiAccountResult.accountList) {
                NSString * title = [account objectForKey:@"name"];
                UIAlertAction * acct = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  handler(account);
                                                              }];
                [alert addAction:acct];
            }
            
            UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            [alert addAction:cancel];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }
    else if([result isKindOfClass:[TradeItErrorResult class]]){
        NSString * errorMessage = @"Could Not Complete Your Order";
        TradeItErrorResult * error = (TradeItErrorResult *) result;
        
        if(error.errorFields.count > 0) {
            NSString * errorField = (NSString *) error.errorFields[0];
            if([errorField isEqualToString:@"authenticationInfo"]) {
                errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
                
                self.tradeSession.resultContainer.status = AUTHENTICATION_ERROR;
                self.tradeSession.resultContainer.errorResponse = error;
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
                                                                       [self dismissViewControllerAnimated:YES completion:nil];
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
                                                                       [self dismissViewControllerAnimated:YES completion:nil];
                                                                   }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}



@end
