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

@implementation TTSDKLoginViewController {
    __weak IBOutlet UILabel *pageTitle;
    __weak IBOutlet UITextField *emailInput;
    __weak IBOutlet UITextField *passwordInput;
    __weak IBOutlet UIButton *linkAccountButton;
    __weak IBOutlet NSLayoutConstraint *linkAccountCenterLineConstraint;

    UIPickerView * currentPicker;
    NSDictionary * currentAccount;

    TTSDKTradeItTicket * globalTicket;
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

    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];

    [utils styleMainInactiveButton:linkAccountButton];
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
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }

    globalTicket.errorMessage = nil;
    globalTicket.errorTitle = nil;
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
                UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {}];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }

            globalTicket.errorMessage = nil;
            globalTicket.errorTitle = nil;
            [utils styleMainActiveButton:linkAccountButton];
        } else {
            TradeItAuthLinkResult * result = (TradeItAuthLinkResult*)res;
            TradeItLinkedLogin * newLinkedLogin = [globalTicket.connector saveLinkToKeychain: result withBroker:self.verifyCreds.broker];
            TTSDKTicketSession * newSession = [[TTSDKTicketSession alloc] initWithConnector:globalTicket.connector andLinkedLogin:newLinkedLogin andBroker:self.verifyCreds.broker];

            [newSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * result) {
                [utils styleMainActiveButton:linkAccountButton];
                
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
                        [globalTicket selectSession:newSession andAccount:selectedAccount];
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
        [utils styleMainActiveButton:linkAccountButton];
    } else {
        [utils styleMainInactiveButton: linkAccountButton];
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
