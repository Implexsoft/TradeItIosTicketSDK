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
#import "TradeItErrorResult.h"
#import "TradeItAuthLinkResult.h"
#import "TradeItAuthenticationResult.h"
#import "TradeItSecurityQuestionResult.h"
#import "TTSDKCustomIOSAlertView.h"

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

    NSString * broker = (self.addBroker == nil) ? globalController.currentSession.broker : self.addBroker;

    if(self.addBroker == nil && globalController.currentSession.login.userId) {
        emailInput.text = globalController.currentSession.login.userId;
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
        NSString * message = [NSString stringWithFormat:@"Please enter a %@ and password.",  [utils getBrokerUsername:globalController.currentSession.broker]];

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
    NSString * broker = self.addBroker == nil ? globalController.currentSession.broker : self.addBroker;
    
    self.verifyCreds = [[TradeItAuthenticationInfo alloc] initWithId:emailInput.text andPassword:passwordInput.text andBroker:broker];

    [globalController.connector linkBrokerWithAuthenticationInfo:self.verifyCreds andCompletionBlock:^(TradeItResult * res){
        if ([res isKindOfClass:TradeItErrorResult.class]) {
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
        } else {
            TradeItAuthLinkResult * result = (TradeItAuthLinkResult*)res;
            TradeItLinkedLogin * newLinkedLogin = [globalController.connector saveLinkToKeychain: result withBroker:self.verifyCreds.broker];
            TTSDKTicketSession * newSession = [[TTSDKTicketSession alloc] initWithConnector:globalController.connector andLinkedLogin:newLinkedLogin andBroker:self.verifyCreds.broker];
            
            [newSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * result) {

                if ([result isKindOfClass:TradeItErrorResult.class]) {
                    
                } else if ([result isKindOfClass:TradeItAuthenticationResult.class]) {

                    TradeItAuthenticationResult * authResult = (TradeItAuthenticationResult *)result;

                    [globalController addSession: newSession];
                    [globalController addAccounts: authResult.accounts];
                    [globalController selectSession:newSession andAccount:[authResult.accounts lastObject]];

                    if (self.isModal) {
                        [self dismissViewControllerAnimated:YES completion:nil];
                    } else {
                        [self performSegueWithIdentifier: @"LoginToTrade" sender: self];
                    }
                }
            }];
        }
    }];
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

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    if (buttonIndex > 0) {
//        [globalController answerSecurityQuestion:[alertView textFieldAtIndex:0].text withCompletionBlock:^(TradeItResult * res){
//            [self authenticateRequestReceived:res];
//        }];
//    }
}



@end
