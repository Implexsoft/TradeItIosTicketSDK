//
//  BrokerSelectDetailViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBrokerSelectDetailViewController.h"
#import "TTSDKUtils.h"
#import "TTSDKCustomAlertView.h"

@implementation TTSDKBrokerSelectDetailViewController {
    
    __weak IBOutlet UILabel *pageTitle;
    __weak IBOutlet UITextField *emailInput;
    __weak IBOutlet UITextField *passwordInput;
    
    __weak IBOutlet UIButton *linkAccountButton;
    
    __weak IBOutlet NSLayoutConstraint *linkAccountCenterLineConstraint;
    
    __weak IBOutlet UIButton *unlinkButton;

    NSDictionary * brokerUsername;

    UIPickerView * currentPicker;
    NSDictionary * currentAccount;

    TTSDKUtils * utils;
}

-(void) viewDidLoad {
    [super viewDidLoad];

    utils = [TTSDKUtils sharedUtils];

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

    [utils styleMainInactiveButton:linkAccountButton];
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
        [utils styleLoadingButton:linkAccountButton];
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
    if ([segue.identifier isEqualToString:@"LoginToOrder"]) {
        UIViewController * nav = [segue destinationViewController];
        TTSDKBrokerSelectViewController * dest = (TTSDKBrokerSelectViewController *)[((UINavigationController *)nav).viewControllers objectAtIndex:0];
        [dest setTradeSession:self.tradeSession];
    } else {
        [[segue destinationViewController] setTradeSession: self.tradeSession];
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



#pragma mark - Verify Credentials

- (void) verifyCredentials {
    TradeItVerifyCredentialsSession * verifyCredsSession = [[TradeItVerifyCredentialsSession alloc] initWithpublisherApp: self.tradeSession.publisherApp];
    NSString * broker = self.addBroker != nil ? self.addBroker : self.tradeSession.broker;
    
    [verifyCredsSession verifyUser: self.verifyCreds withBroker:broker WithCompletionBlock:^(TradeItResult * res){
        [self verifyCredentialsRequestRecieved: res];
    }];
}

-(void) verifyCredentialsRequestRecieved: (TradeItResult *) result {

    [utils styleMainActiveButton:linkAccountButton];

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

            [self performSegueWithIdentifier: @"LoginToOrder" sender: self];
            NSArray * fakeAccounts = [NSArray arrayWithObjects:
                                      [NSDictionary dictionaryWithObjectsAndKeys:@"Fidelity*2345",@"name",nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:@"Fidelity*9283",@"name",nil],
                                      nil];

            if(![UIAlertController class]) {
                [self showOldAcctSelect: fakeAccounts];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Accounts To Link"
                                                                                message:nil
                                                                         preferredStyle:UIAlertControllerStyleActionSheet];

                void (^handler)(NSDictionary * account) = ^(NSDictionary * account){
                    [[self tradeSession] asyncSelectAccount:account andCompletionBlock:^(TradeItResult *result) {
                        [self loginComplete];
                    }];
                };

                for (NSDictionary * account in fakeAccounts) {
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

            
//            TTSDKCustomAlertView * alert = [utils customAlertWithVC:self];
//            [self.view addSubview:alert];


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


-(void) loginComplete {
    
}


#pragma mark - iOS7 fallback

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) showOldAcctSelect: (NSArray *)accounts {
    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];


    [alert setContainerView:[self createAccountPickerView]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];

    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 0) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [[self tradeSession] asyncSelectAccount:currentAccount andCompletionBlock:^(TradeItResult *result) {

            }];
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
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

@end
