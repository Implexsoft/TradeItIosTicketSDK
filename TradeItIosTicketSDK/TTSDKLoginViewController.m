//
//  TTSDKLoginViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKLoginViewController.h"
#import "TTSDKUtils.h"
#import "TTSDKCustomAlertView.h"
#import "TradeItAuthLinkResult.h"
#import "TradeItErrorResult.h"
#import "TTSDKTicketController.h"

#import "TradeItSuccessAuthenticationResult.h"

@implementation TTSDKLoginViewController {
    
    __weak IBOutlet UILabel *pageTitle;
    __weak IBOutlet UITextField *emailInput;
    __weak IBOutlet UITextField *passwordInput;
    __weak IBOutlet UIButton *linkAccountButton;
    __weak IBOutlet NSLayoutConstraint *linkAccountCenterLineConstraint;
    __weak IBOutlet UIButton *unlinkButton;

    UIPickerView * currentPicker;
    NSDictionary * currentAccount;

    TTSDKTicketController * globalController;

    TTSDKUtils * utils;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}

-(void) viewDidLoad {
    [super viewDidLoad];

    utils = [TTSDKUtils sharedUtils];

    globalController = [TTSDKTicketController globalController];

    self.tradeSession = [TTSDKTicketSession globalSession];

    NSString * broker = self.addBroker == nil ? globalController.currentBroker : self.addBroker;

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

        if (self.tradeSession.brokerSignUpCallback) {
            self.tradeSession.brokerSignUpCallback(res);
        }

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
        NSString * message = [NSString stringWithFormat:@"Please enter a %@ and password.",  [TTSDKTradeItTicket getBrokerUsername:self.tradeSession.broker]];

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
        self.tradeSession.errorTitle = @"Invalid Credentials";
        self.tradeSession.errorMessage = @"Check your username and password and try again.";

//        if(!self.addBroker) {
//            [TTSDKTradeItTicket storeUsername:self.verifyCreds.id andPassword:@"" forBroker:self.addBroker];
//            [TTSDKTradeItTicket removeLinkedBroker: self.addBroker];
//        }

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
        [self performSegueWithIdentifier: @"LoginToTrade" sender: self];
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
