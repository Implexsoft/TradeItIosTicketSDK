//
//  TTSDKLoginViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKLoginViewController.h"
#import "TTSDKTicketController.h"
#import "TTSDKUtils.h"
#import "TTSDKCustomAlertView.h"
#import "TradeItErrorResult.h"
#import "TradeItAuthLinkResult.h"
#import "TradeItAuthenticationResult.h"
#import "TradeItSecurityQuestionResult.h"

@implementation TTSDKLoginViewController {
    __weak IBOutlet UILabel *pageTitle;
    __weak IBOutlet UITextField *emailInput;
    __weak IBOutlet UITextField *passwordInput;
    __weak IBOutlet UIButton *linkAccountButton;
    __weak IBOutlet NSLayoutConstraint *linkAccountCenterLineConstraint;

    UIPickerView * currentPicker;
    NSDictionary * currentAccount;

    TTSDKTicketController * globalController;
    TTSDKUtils * utils;
}



#pragma mark - Rotation

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}



#pragma mark - Initialization

-(void) viewDidLoad {
    [super viewDidLoad];

    utils = [TTSDKUtils sharedUtils];
    globalController = [TTSDKTicketController globalController];

    NSString * broker = (self.addBroker == nil) ? globalController.currentBroker : self.addBroker;

    if(self.addBroker == nil && globalController.currentLogin.userId) {
        emailInput.text = globalController.currentLogin.userId;
    }

    if(self.cancelToParent) {
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(home:)];
        self.navigationItem.leftBarButtonItem=newBackButton;
    }

    [pageTitle setText:[NSString stringWithFormat:@"Log in to %@", [globalController getBrokerDisplayString:broker]]];

    [emailInput setDelegate:self];
    [passwordInput setDelegate:self];

    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];

    [utils styleMainInactiveButton:linkAccountButton];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self checkAuthState];

    if(globalController.errorTitle) {
        if(![UIAlertController class]) {
            [self showOldErrorAlert:globalController.errorTitle withMessage:globalController.errorMessage];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:globalController.errorTitle
                                                                            message:globalController.errorMessage
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }

    globalController.errorMessage = nil;
    globalController.errorTitle = nil;
}

- (void)dismissKeyboard {
    [emailInput resignFirstResponder];
    [passwordInput resignFirstResponder];
}



#pragma mark - Authentication

-(void) checkAuthState {
    if(globalController.brokerSignUpComplete) {
        TradeItAuthControllerResult * res = [[TradeItAuthControllerResult alloc] init];
        res.success = true;

        if (globalController.brokerSignUpCallback) {
            globalController.brokerSignUpCallback(res);
        }

        return;
    }
}

- (IBAction)linkAccountPressed:(id)sender {
    if (emailInput.isFirstResponder) {
        [emailInput resignFirstResponder];
    }
    
    if (passwordInput.isFirstResponder) {
        [passwordInput resignFirstResponder];
    }

    if(emailInput.text.length < 1 || passwordInput.text.length < 1) {
        NSString * message = [NSString stringWithFormat:@"Please enter a %@ and password.",  [utils getBrokerUsername:globalController.currentBroker]];

        if(![UIAlertController class]) {
            [self showOldErrorAlert:@"Invalid Credentials" withMessage:message];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Invalid Credentials"
                                                                            message:message
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }

    } else {
        [utils styleLoadingButton:linkAccountButton];
        [self authenticate];
    }
}

-(void) authenticate {
    NSString * broker = self.addBroker == nil ? globalController.currentBroker : self.addBroker;
    
    self.verifyCreds = [[TradeItAuthenticationInfo alloc] initWithId:emailInput.text andPassword:passwordInput.text andBroker:broker];
    
    [globalController authenticate:self.verifyCreds withCompletionBlock:^(TradeItResult * res){
        [self authenticateRequestReceived: res];
    }];
}

-(void) authenticateRequestReceived: (TradeItResult *) result {
    [utils styleMainActiveButton:linkAccountButton];
    
    if ([result isKindOfClass:TradeItErrorResult.class]) {
        globalController.errorTitle = @"Invalid Credentials";
        globalController.errorMessage = @"Check your username and password and try again.";
        
        if(![UIAlertController class]) {
            [self showOldErrorAlert:globalController.errorTitle withMessage:globalController.errorMessage];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:globalController.errorTitle
                                                                            message:globalController.errorMessage
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
        
        globalController.errorMessage = nil;
        globalController.errorTitle = nil;
    } else if ([result isKindOfClass:TradeItSecurityQuestionResult.class]) {
        TradeItSecurityQuestionResult * res = (TradeItSecurityQuestionResult *)result;
        
        if (res.securityQuestionOptions != nil && res.securityQuestionOptions.count > 0) {
            [self showOldMultiSelect:res];
        } else if (res.securityQuestion != nil) {
            [self showOldSecQuestion:res.securityQuestion];
        }
    } else {
        NSArray * accounts = [result valueForKey:@"accounts"];
        [globalController addAccounts:accounts];
        [globalController selectAccount:(NSDictionary *)[accounts lastObject]];
        
        [self performSegueWithIdentifier: @"LoginToTrade" sender: self];
    }
}



#pragma mark - Text Editing Delegates

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

-(BOOL) textFieldShouldEndEditing:(UITextField *)textField {
    if(emailInput.text.length >= 1 && passwordInput.text.length >= 1) {
        [utils styleMainActiveButton:linkAccountButton];
    }

    return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    if(emailInput.text.length < 1) {
        [emailInput becomeFirstResponder];
    } else if(passwordInput.text.length < 1) {
        [passwordInput becomeFirstResponder];
    } else {
        [self linkAccountPressed:self];
    }

    return YES;
}



#pragma mark - Navigation

-(void)home:(UIBarButtonItem *)sender {
    [globalController returnToParentApp];
}



#pragma mark - iOS7 fallback

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
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
    currentPicker = picker;

    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [contentView addSubview:picker];

    [contentView setNeedsDisplay];
    return contentView;
}

-(NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex > 0) {
        [globalController answerSecurityQuestion:[alertView textFieldAtIndex:0].text withCompletionBlock:^(TradeItResult * res){
            [self authenticateRequestReceived:res];
        }];
    }
}

-(void) showOldSecQuestion:(NSString *) question {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:@"Security Question" message:question delegate: self cancelButtonTitle:@"CANCEL" otherButtonTitles: @"SUBMIT", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.questionOptions.count;
}

-(void) showOldMultiSelect:(TradeItSecurityQuestionResult *) securityQuestionResult {
    self.questionOptions = securityQuestionResult.securityQuestionOptions;
    self.currentSelection = self.questionOptions[0];

    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView: @"Security Question"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SUBMIT",nil]];

    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 0) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [globalController answerSecurityQuestion:self.currentSelection withCompletionBlock:^(TradeItResult *result) {
                [self authenticateRequestReceived:result];
            }];
        }
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}



@end
