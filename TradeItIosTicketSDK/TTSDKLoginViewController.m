//
//  TTSDKLoginViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKLoginViewController.h"
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
    __weak IBOutlet NSLayoutConstraint *loginButtonBottomConstraint;

    UIPickerView * currentPicker;
    NSDictionary * currentAccount;
}


#pragma mark Rotation

-(BOOL) shouldAutorotate {
    return NO;
}

-(UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

-(UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark Initialization

-(void) viewDidLoad {
    [super viewDidLoad];

    // Add a "textFieldDidChange" notification method to the text field control.
    [emailInput addTarget:self
                  action:@selector(textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];

    [passwordInput addTarget:self
                   action:@selector(textFieldDidChange:)
         forControlEvents:UIControlEventEditingChanged];

    NSString * broker = (self.addBroker == nil) ? self.ticket.currentSession.broker : self.addBroker;

    if(self.cancelToParent) {
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(home:)];
        self.navigationItem.leftBarButtonItem=newBackButton;
    }

    // Listen for keyboard appearances and disappearances
    if (![self.utils isSmallScreen]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidShow:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHide:)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
    }

    [pageTitle setText:[NSString stringWithFormat:@"Log in to %@", [self.ticket getBrokerDisplayString:broker]]];

    [emailInput setDelegate:self];
    [passwordInput setDelegate:self];

    emailInput.attributedPlaceholder = [[NSAttributedString alloc] initWithString:[self.utils getBrokerUsername: broker] attributes: @{NSForegroundColorAttributeName: self.styles.primaryPlaceholderColor}];
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

    if(self.ticket.errorTitle) {
        if(![UIAlertController class]) {
            [self showOldErrorAlert:self.ticket.errorTitle withMessage:self.ticket.errorMessage];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:self.ticket.errorTitle
                                                                            message:self.ticket.errorMessage
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

    self.ticket.errorMessage = nil;
    self.ticket.errorTitle = nil;

    [emailInput becomeFirstResponder];
}

-(void) dismissKeyboard {
    [emailInput resignFirstResponder];
    [passwordInput resignFirstResponder];
}


#pragma mark Authentication

-(void) checkAuthState {
    if(self.ticket.brokerSignUpComplete) {
        TradeItAuthControllerResult * res = [[TradeItAuthControllerResult alloc] init];
        res.success = true;

//        if (self.ticket.brokerSignUpCallback) {
//            self.ticket.brokerSignUpCallback(res);
//        }

        return;
    }
}

-(IBAction) linkAccountPressed:(id)sender {
    if (emailInput.isFirstResponder) {
        [emailInput resignFirstResponder];
    }
    
    if (passwordInput.isFirstResponder) {
        [passwordInput resignFirstResponder];
    }

    if(emailInput.text.length < 1 || passwordInput.text.length < 1) {
        NSString * message = [NSString stringWithFormat:@"Please enter a %@ and password.",  [self.utils getBrokerUsername: self.ticket.currentSession.broker]];

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
    NSString * broker = self.addBroker == nil ? self.ticket.currentSession.broker : self.addBroker;

    self.verifyCreds = [[TradeItAuthenticationInfo alloc] initWithId:emailInput.text andPassword:passwordInput.text andBroker:broker];

    [self.ticket.connector linkBrokerWithAuthenticationInfo:self.verifyCreds andCompletionBlock:^(TradeItResult * res){
        if ([res isKindOfClass:TradeItErrorResult.class]) {

            TradeItErrorResult * error = (TradeItErrorResult *)res;

            NSMutableString * errorMessage = [[NSMutableString alloc] initWithString:@""];

            for (NSString * message in error.longMessages) {
                [errorMessage appendString: message];
            }

            self.ticket.errorTitle = error.shortMessage;
            self.ticket.errorMessage = [errorMessage copy];

            if(![UIAlertController class]) {
                [self showOldErrorAlert:self.ticket.errorTitle withMessage:self.ticket.errorMessage];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:self.ticket.errorTitle
                                                                                message:self.ticket.errorMessage
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

            self.ticket.errorMessage = nil;
            self.ticket.errorTitle = nil;
            [linkAccountButton exitLoadingState];
            [linkAccountButton activate];
        } else {
            TradeItAuthLinkResult * result = (TradeItAuthLinkResult*)res;
            TradeItLinkedLogin * newLinkedLogin = [self.ticket.connector saveLinkToKeychain: result withBroker:self.verifyCreds.broker];
            TTSDKTicketSession * newSession = [[TTSDKTicketSession alloc] initWithConnector:self.ticket.connector andLinkedLogin:newLinkedLogin andBroker:self.verifyCreds.broker];

            [newSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * result) {
                [linkAccountButton exitLoadingState];
                [linkAccountButton activate];

                if ([result isKindOfClass:TradeItErrorResult.class]) {
                    self.ticket.resultContainer.status = AUTHENTICATION_ERROR;

                    if(self.ticket.brokerSignUpCallback) {
                        TradeItAuthControllerResult * res = [[TradeItAuthControllerResult alloc] initWithResult: result];
                        self.ticket.brokerSignUpCallback(res);
                    }

                    [self.ticket returnToParentApp];

                } else if ([result isKindOfClass:TradeItAuthenticationResult.class]) {

                    TradeItAuthenticationResult * authResult = (TradeItAuthenticationResult *)result;

                    if ([self.ticket checkIsAuthenticationDuplicate: authResult.accounts]) {
                        [self.ticket replaceAccountsWithNewAccounts: authResult.accounts];
                    }

                    [self.ticket addSession: newSession];
                    [self.ticket addAccounts: authResult.accounts withSession: newSession];

                    NSDictionary * lastAccount = [authResult.accounts lastObject];
                    NSDictionary * selectedAccount;
                    for (NSDictionary *account in self.ticket.allAccounts) {
                        if ([[lastAccount valueForKey:@"accountNumber"] isEqualToString:[account valueForKey:@"accountNumber"]]) {
                            selectedAccount = account;
                        }
                    }

                    // If the auth flow was triggered modally, then we don't want to automatically select it
                    if (self.ticket.presentationMode == TradeItPresentationModeAuth) {
                        self.ticket.resultContainer.status = AUTHENTICATION_SUCCESS;

                        if(self.ticket.brokerSignUpCallback) {
                            TradeItAuthControllerResult * res = [[TradeItAuthControllerResult alloc] initWithResult:result];
                            self.ticket.brokerSignUpCallback(res);
                        }

                        [self.ticket returnToParentApp];
                    } else if (self.isModal) {
                        [self dismissViewControllerAnimated:YES completion:nil];
                    } else {
                        [self.ticket selectCurrentSession:newSession andAccount:selectedAccount];

                        if (self.ticket.presentationMode == TradeItPresentationModePortfolioOnly) {
                            [self performSegueWithIdentifier: @"LoginToPortfolioNav" sender: self];
                        } else if (self.ticket.presentationMode == TradeItPresentationModeTradeOnly) {
                            [self performSegueWithIdentifier: @"LoginToTradeNav" sender: self];
                        } else if (self.ticket.presentationMode == TradeItPresentationModeAccounts) {
                            [self performSegueWithIdentifier:@"LoginToAccountLink" sender:self];
                        } else {
                            [self performSegueWithIdentifier: @"LoginToTab" sender: self];
                        }
                    }
                }
            }];
        }
    }];
}


#pragma mark Text Editing Delegates

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

-(void) keyboardDidShow: (NSNotification *) notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];

    loginButtonBottomConstraint.constant = keyboardFrameBeginRect.size.height + 20.0f;
}

-(void) keyboardDidHide: (NSNotification *) notification {
    loginButtonBottomConstraint.constant = 20.0f;
}

-(void) textFieldDidChange:(UITextField *)textField {
    if(emailInput.text.length >= 1 && passwordInput.text.length >= 1) {
        [linkAccountButton activate];
    } else {
        [linkAccountButton deactivate];
    }
}


#pragma mark Navigation

-(void) home:(UIBarButtonItem *)sender {
    if (self.cancelToParent) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.ticket returnToParentApp];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"LoginToTab"]) {
        UITabBarController * dest = (UITabBarController*)segue.destinationViewController;
        if (self.ticket.presentationMode == TradeItPresentationModePortfolio || self.ticket.presentationMode == TradeItPresentationModePortfolioOnly) {
            dest.selectedIndex = 1;
        }
    } else if ([segue.identifier isEqualToString:@"LoginToAccountSelect"]) {
        UINavigationController * nav = (UINavigationController *)[segue destinationViewController];
        [self.ticket configureAccountLinkNavController: nav];
    }
}


#pragma mark iOS7 fallback

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // nothing to do
}


@end
