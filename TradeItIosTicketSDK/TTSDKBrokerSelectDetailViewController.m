//
//  BrokerSelectDetailViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBrokerSelectDetailViewController.h"
#import "TTSDKHelper.h"

@implementation TTSDKBrokerSelectDetailViewController {
    
    __weak IBOutlet UILabel *pageTitle;
    __weak IBOutlet UITextField *emailInput;
    __weak IBOutlet UITextField *passwordInput;
    
    __weak IBOutlet UIButton *linkAccountButton;
    
    __weak IBOutlet NSLayoutConstraint *linkAccountCenterLineConstraint;
    
    __weak IBOutlet UIButton *unlinkButton;

    NSDictionary * brokerUsername;
    
    TTSDKHelper * helper;
}

-(void) viewDidLoad {
    [super viewDidLoad];

    helper = [TTSDKHelper sharedHelper];

    self.view.superview.backgroundColor = [UIColor whiteColor];

    NSString * broker = self.addBroker == nil ? self.tradeSession.broker : self.addBroker;

    brokerUsername = @{
          @"Dummy":@"Username",
          @"TD":@"User Id",
          @"Robinhood":@"Username",
          @"OptionsHouse":@"User Id",
          @"Schwabs":@"User Id",
          @"TradeStation":@"Username",
          @"Etrade":@"User Id",
          @"Fidelity":@"Username",
          @"Scottrade":@"Account #",
          @"Tradier":@"Username",
          @"IB":@"Username",
    };

    if(self.addBroker == nil) {
        emailInput.text = self.tradeSession.authenticationInfo.id;
    }

    if(self.cancelToParent) {
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(home:)];
        self.navigationItem.leftBarButtonItem=newBackButton;
    }

    [pageTitle setText:[NSString stringWithFormat:@"Log in to %@", [TTSDKTradeItTicket getBrokerDisplayString:broker]]];
    
    if(![[TTSDKTradeItTicket getLinkedBrokersList] containsObject:broker]){
        unlinkButton.hidden = YES;
    }

    [emailInput setDelegate:self];
    [passwordInput setDelegate:self];

    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];

    //[helper styleMainActiveButton:linkAccountButton];
    [helper styleMainInactiveButton:linkAccountButton];
}

- (void)dismissKeyboard {
    [emailInput resignFirstResponder];
    [passwordInput resignFirstResponder];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self checkAuthState];

    if(self.tradeSession.errorTitle) {
        if(![UIAlertController class]) {
            [self showOldErrorAlert:self.tradeSession.errorTitle withMessage:self.tradeSession.errorMessage];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:self.tradeSession.errorTitle
                                                                            message:self.tradeSession.errorMessage
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    
    self.tradeSession.errorMessage = nil;
    self.tradeSession.errorTitle = nil;
}

-(void) checkAuthState {
    if(self.tradeSession.brokerSignUpComplete) {
        TradeItAuthControllerResult * res = [[TradeItAuthControllerResult alloc] init];
        res.success = true;
        
        self.tradeSession.brokerSignUpCallback(res);
        [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
        
        return;
    }
}

-(void)home:(UIBarButtonItem *)sender {
    [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
}

- (IBAction)linkAccountPressed:(id)sender {
    if (emailInput.isFirstResponder) {
        [emailInput resignFirstResponder];
    }
    
    if (passwordInput.isFirstResponder) {
        [passwordInput resignFirstResponder];
    }
    
    if(emailInput.text.length < 1 || passwordInput.text.length < 1) {
        NSString * message = [NSString stringWithFormat:@"Please enter a %@ and password.", brokerUsername[self.tradeSession.broker]];

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
        [helper styleLoadingButton:linkAccountButton];
        [self setVerifyCreds: [[TradeItAuthenticationInfo alloc]initWithId:emailInput.text andPassword:passwordInput.text]];
        [self verifyCredentials];
    }
}

-(IBAction) unlinkAccountPressed:(id) sender{
    NSString * broker = self.addBroker == nil ? self.tradeSession.broker : self.addBroker;

    [TTSDKTradeItTicket storeUsername:@"" andPassword:@"" forBroker:broker];
    [TTSDKTradeItTicket removeLinkedBroker: broker];

    if([self.tradeSession.broker isEqualToString:broker]) {
        self.tradeSession.broker = nil;
        self.tradeSession.authenticationInfo.id = @"";
        self.tradeSession.authenticationInfo.password = @"";
    }

    [TTSDKTradeItTicket restartTicket:self.tradeSession];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [[segue destinationViewController] setTradeSession: self.tradeSession];
}



#pragma mark - Text Editing Delegates

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

-(BOOL) textFieldShouldEndEditing:(UITextField *)textField {
    if(emailInput.text.length >= 1 && passwordInput.text.length >= 1) {
        [helper styleMainActiveButton:linkAccountButton];
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



#pragma mark - Verify Credentials

- (void) verifyCredentials {
    TradeItVerifyCredentialsSession * verifyCredsSession = [[TradeItVerifyCredentialsSession alloc] initWithpublisherApp: self.tradeSession.publisherApp];
    NSString * broker = self.addBroker != nil ? self.addBroker : self.tradeSession.broker;
    
    [verifyCredsSession verifyUser: self.verifyCreds withBroker:broker WithCompletionBlock:^(TradeItResult * res){
        [self verifyCredentialsRequestRecieved: res];
    }];
}

-(void) verifyCredentialsRequestRecieved: (TradeItResult *) result {

    [helper styleMainActiveButton:linkAccountButton];

    if([result isKindOfClass:[TradeItErrorResult class]]) {
        TradeItErrorResult * err = (TradeItErrorResult *) result;
        
        self.tradeSession.errorTitle = err.shortMessage; // keeping this flow, in case it's used somewhere else in the application
        self.tradeSession.errorMessage = [err.longMessages componentsJoinedByString:@"\n"];

        if(![UIAlertController class]) {
            [self showOldErrorAlert:self.tradeSession.errorTitle withMessage:self.tradeSession.errorMessage];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:self.tradeSession.errorTitle
                                                                            message:self.tradeSession.errorMessage
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }

        self.tradeSession.errorMessage = nil;
        self.tradeSession.errorTitle = nil;
    } else {
        TradeItSuccessAuthenticationResult * success = (TradeItSuccessAuthenticationResult *) result;
        NSString * broker = self.addBroker != nil ? self.addBroker : self.tradeSession.broker;
        
        if(success.credentialsValid) {
            [TTSDKTradeItTicket storeUsername:self.verifyCreds.id andPassword:self.verifyCreds.password forBroker:broker];
            [TTSDKTradeItTicket addLinkedBroker:broker];
            self.tradeSession.resultContainer.status = USER_CANCELED;
            
            if(self.addBroker) {
                self.tradeSession.broker = self.addBroker;
            }
            
            self.tradeSession.authenticationInfo = self.verifyCreds;
            self.tradeSession.brokerSignUpComplete = true;

            [self performSegueWithIdentifier: @"LoginToCalculator" sender: self];
        } else {
            self.tradeSession.errorTitle = @"Invalid Credentials";
            self.tradeSession.errorMessage = @"Check your username and password and try again.";

            if(!self.addBroker) {
                [TTSDKTradeItTicket storeUsername:self.verifyCreds.id andPassword:@"" forBroker:broker];
                [TTSDKTradeItTicket removeLinkedBroker: broker];
            }

            if(![UIAlertController class]) {
                [self showOldErrorAlert:self.tradeSession.errorTitle withMessage:self.tradeSession.errorMessage];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:self.tradeSession.errorTitle
                                                                                message:self.tradeSession.errorMessage
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {}];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
            
            self.tradeSession.errorMessage = nil;
            self.tradeSession.errorTitle = nil;
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

@end
