//
//  TTSDKLoginViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKLoginViewController.h"
#import "TTSDKTradeItTicket.h"
#import "TTSDKUtils.h"
#import "TradeItErrorResult.h"
#import "TradeItAuthLinkResult.h"
#import "TradeItAuthenticationResult.h"
#import "TradeItSecurityQuestionResult.h"
#import "TTSDKCustomIOSAlertView.h"
#import "TTSDKPrimaryButton.h"

@implementation TTSDKLoginViewController {
    __weak IBOutlet UILabel *pageTitle;
    __weak IBOutlet UITextField *emailInput;
    __weak IBOutlet UITextField *passwordInput;
    __weak IBOutlet TTSDKPrimaryButton *linkAccountButton;
    __weak IBOutlet NSLayoutConstraint *linkAccountCenterLineConstraint;

    UIPickerView * currentPicker;
    NSDictionary * currentAccount;

    TTSDKTradeItTicket * globalTicket;
    TTSDKUtils * utils;
}



#pragma mark - Rotation

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}



#pragma mark - Initialization

-(void) viewDidLoad {
    [super viewDidLoad];

    utils = [TTSDKUtils sharedUtils];
    globalTicket = [TTSDKTradeItTicket globalTicket];

    NSString * broker = (self.addBroker == nil) ? globalTicket.currentSession.broker : self.addBroker;

    if(self.addBroker == nil && globalTicket.currentSession.login.userId) {
        emailInput.text = globalTicket.currentSession.login.userId;
    }

    if(self.cancelToParent) {
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(home:)];
        self.navigationItem.leftBarButtonItem=newBackButton;
    }

    [pageTitle setText:[NSString stringWithFormat:@"Log in to %@", [globalTicket getBrokerDisplayString:broker]]];

    [emailInput setDelegate:self];
    [passwordInput setDelegate:self];

    emailInput.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Broker username" attributes: @{NSForegroundColorAttributeName: self.styles.primaryPlaceholderColor}];
    passwordInput.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Broker password" attributes: @{NSForegroundColorAttributeName: self.styles.primaryPlaceholderColor}];

    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];

    [linkAccountButton deactivate];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self checkAuthState];

    if(globalTicket.errorTitle) {
        if(![UIAlertController class]) {
            [self showOldErrorAlert:globalTicket.errorTitle withMessage:globalTicket.errorMessage];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:globalTicket.errorTitle
                                                                            message:globalTicket.errorMessage
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            alert.modalPresentationStyle = UIModalPresentationPopover;
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
            alertPresentationController.sourceView = self.view;
            alertPresentationController.permittedArrowDirections = 0;
            alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
        }
    }

    globalTicket.errorMessage = nil;
    globalTicket.errorTitle = nil;

    [emailInput becomeFirstResponder];
}

- (void)dismissKeyboard {
    [emailInput resignFirstResponder];
    [passwordInput resignFirstResponder];
}



#pragma mark - Authentication

-(void) checkAuthState {
    if(globalTicket.brokerSignUpComplete) {
        TradeItAuthControllerResult * res = [[TradeItAuthControllerResult alloc] init];
        res.success = true;

//        if (globalTicket.brokerSignUpCallback) {
//            globalTicket.brokerSignUpCallback(res);
//        }

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
        NSString * message = [NSString stringWithFormat:@"Please enter a %@ and password.",  [utils getBrokerUsername:globalTicket.currentSession.broker]];

        if(![UIAlertController class]) {
            [self showOldErrorAlert:@"Invalid Credentials" withMessage:message];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Invalid Credentials"
                                                                            message:message
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            alert.modalPresentationStyle = UIModalPresentationPopover;
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
            alertPresentationController.sourceView = self.view;
            alertPresentationController.permittedArrowDirections = 0;
            alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
        }

    } else {
        [linkAccountButton enterLoadingState];

        [self authenticate];
    }
}

-(void) authenticate {
    NSString * broker = self.addBroker == nil ? globalTicket.currentSession.broker : self.addBroker;
    
    self.verifyCreds = [[TradeItAuthenticationInfo alloc] initWithId:emailInput.text andPassword:passwordInput.text andBroker:broker];

    [globalTicket.connector linkBrokerWithAuthenticationInfo:self.verifyCreds andCompletionBlock:^(TradeItResult * res){
        if ([res isKindOfClass:TradeItErrorResult.class]) {
            globalTicket.errorTitle = @"Invalid Credentials";
            globalTicket.errorMessage = @"Check your username and password and try again.";
            
            if(![UIAlertController class]) {
                [self showOldErrorAlert:globalTicket.errorTitle withMessage:globalTicket.errorMessage];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:globalTicket.errorTitle
                                                                                message:globalTicket.errorMessage
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                alert.modalPresentationStyle = UIModalPresentationPopover;
                UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {}];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
                UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
                alertPresentationController.sourceView = self.view;
                alertPresentationController.permittedArrowDirections = 0;
                alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
            }

            globalTicket.errorMessage = nil;
            globalTicket.errorTitle = nil;
            [linkAccountButton activate];
        } else {
            TradeItAuthLinkResult * result = (TradeItAuthLinkResult*)res;
            TradeItLinkedLogin * newLinkedLogin = [globalTicket.connector saveLinkToKeychain: result withBroker:self.verifyCreds.broker];
            TTSDKTicketSession * newSession = [[TTSDKTicketSession alloc] initWithConnector:globalTicket.connector andLinkedLogin:newLinkedLogin andBroker:self.verifyCreds.broker];

            [newSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * result) {
                [linkAccountButton activate];

                if ([result isKindOfClass:TradeItErrorResult.class]) {

                } else if ([result isKindOfClass:TradeItAuthenticationResult.class]) {

                    TradeItAuthenticationResult * authResult = (TradeItAuthenticationResult *)result;

                    [globalTicket addSession: newSession];
                    [globalTicket addAccounts: authResult.accounts withSession: newSession];

                    NSDictionary * lastAccount = [authResult.accounts lastObject];
                    NSDictionary * selectedAccount;
                    for (NSDictionary *account in globalTicket.allAccounts) {
                        if ([[lastAccount valueForKey:@"accountNumber"] isEqualToString:[account valueForKey:@"accountNumber"]]) {
                            selectedAccount = account;
                        }
                    }

                    // If the auth flow was triggered modally, then we don't want to automatically select it
                    if (self.isModal) {
                        [self dismissViewControllerAnimated:YES completion:nil];
                    } else {
                        [globalTicket selectCurrentSession:newSession andAccount:selectedAccount];
                        [self performSegueWithIdentifier: @"LoginToTab" sender: self];
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
        [linkAccountButton activate];
    } else {
        [linkAccountButton deactivate];
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
    [globalTicket returnToParentApp];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"LoginToTab"]) {
        UITabBarController * dest = (UITabBarController*)segue.destinationViewController;
        if (globalTicket.portfolioMode) {
            dest.selectedIndex = 1;
        }
    }
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
//        [globalTicket answerSecurityQuestion:[alertView textFieldAtIndex:0].text withCompletionBlock:^(TradeItResult * res){
//            [self authenticateRequestReceived:res];
//        }];
//    }
}



@end
