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
    
    UIButton * unlinkButton;

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
    
    if([[TTSDKTradeItTicket getLinkedBrokersList] containsObject:broker]){
        [self addUnlink];
    }
    
    [emailInput setDelegate:self];
    [passwordInput setDelegate:self];

    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];

    linkAccountButton.backgroundColor = helper.activeButtonColor;
    CAGradientLayer * buttonGrLayer = [helper activeGradientWithBounds: linkAccountButton.layer.bounds];
    buttonGrLayer.zPosition = -1.0;
    [linkAccountButton.layer addSublayer:buttonGrLayer];
    linkAccountButton.layer.cornerRadius = 22.0f;
    linkAccountButton.clipsToBounds = YES;
}

- (void)dismissKeyboard {
    [emailInput resignFirstResponder];
    [passwordInput resignFirstResponder];
}

-(void) addUnlink {
    unlinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [unlinkButton addTarget:self
               action:@selector(unlinkAccountPressed:)
     forControlEvents:UIControlEventTouchUpInside];
    [unlinkButton setTitle:@"Unlink Account" forState:UIControlStateNormal];
    [unlinkButton setTranslatesAutoresizingMaskIntoConstraints:NO];

    unlinkButton.clipsToBounds = YES;
    unlinkButton.layer.cornerRadius = unlinkButton.frame.size.height / 2;
    unlinkButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    unlinkButton.frame = linkAccountButton.frame;
    unlinkButton.bounds = linkAccountButton.bounds;

    NSLayoutConstraint * topConstraint = [NSLayoutConstraint
                                             constraintWithItem:unlinkButton
                                             attribute:NSLayoutAttributeBottom
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:linkAccountButton
                                             attribute:NSLayoutAttributeTop
                                             multiplier:1
                                             constant:-20];
    topConstraint.priority = 900;
    
    NSLayoutConstraint * leftConstraint = [NSLayoutConstraint
                                          constraintWithItem:unlinkButton
                                          attribute:NSLayoutAttributeLeading
                                          relatedBy:NSLayoutRelationEqual
                                          toItem:self.view
                                          attribute:NSLayoutAttributeLeadingMargin
                                          multiplier:1
                                          constant:0];
    leftConstraint.priority = 900;
    
    NSLayoutConstraint * rightConstraint = [NSLayoutConstraint
                                           constraintWithItem:linkAccountButton
                                           attribute:NSLayoutAttributeTrailing
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:self.view
                                           attribute:NSLayoutAttributeTrailingMargin
                                           multiplier:1
                                           constant:0];
    rightConstraint.priority = 900;

    [self.view addSubview:unlinkButton];
    
    [self.view removeConstraint:linkAccountCenterLineConstraint];
    [self.view addConstraint:topConstraint];
    [self.view addConstraint:leftConstraint];
    [self.view addConstraint:rightConstraint];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(self.tradeSession.brokerSignUpComplete) {
        TradeItAuthControllerResult * res = [[TradeItAuthControllerResult alloc] init];
        res.success = true;

        self.tradeSession.brokerSignUpCallback(res);
        [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
        
        return;
    }
    
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
        [self performSegueWithIdentifier: @"loginToLoading" sender: self];
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
    if(![[segue identifier] isEqualToString:@"unwindToBrokerSelect"]) {
        [[segue destinationViewController] setActionToPerform: @"verifyCredentials"];
        [[segue destinationViewController] setAddBroker: self.addBroker];
        [[segue destinationViewController] setVerifyCreds: [[TradeItAuthenticationInfo alloc]initWithId:emailInput.text andPassword:passwordInput.text]];
    }
    
    [[segue destinationViewController] setTradeSession: self.tradeSession];
}

#pragma mark - Text Editing Delegates

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:0.35f];
//    
//    CGRect frame = linkAccountButton.frame;
//    frame.origin.y = frame.origin.y - 220;
//    [linkAccountButton setFrame:frame];
//    
//    [UIView commitAnimations];
    
    return YES;
}

-(BOOL) textFieldShouldEndEditing:(UITextField *)textField {
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:0.35f];
//    
//    CGRect frame = linkAccountButton.frame;
//    frame.origin.y = frame.origin.y + 220;
//    [linkAccountButton setFrame:frame];
//
//    [UIView commitAnimations];
    
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

#pragma mark - iOS7 fallback

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

@end

















