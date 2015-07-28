//
//  BrokerSelectDetailViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "BrokerSelectDetailViewController.h"

@implementation BrokerSelectDetailViewController {
    
    __weak IBOutlet UILabel *pageTitle;
    __weak IBOutlet UITextField *emailInput;
    __weak IBOutlet UITextField *passwordInput;
    
    __weak IBOutlet UIButton *linkAccountButton;
    
    __weak IBOutlet NSLayoutConstraint *linkAccountCenterLineConstraint;
    
    UIButton * unlinkButton;
    
    NSDictionary * brokerUsername;
}

-(void) viewDidLoad {
    NSString * broker = self.addBroker == nil ? self.tradeSession.broker : self.addBroker;
    
    /*  This might be nice at some point
    UIImage * image = [UIImage imageNamed: [NSString stringWithFormat: @"TradeItIosTicketSDK.bundle/%@.png", broker]];
    logo.image = image;
    [logo setContentMode: UIViewContentModeScaleAspectFit];
    */
    
    emailInput.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    passwordInput.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    
    emailInput.layer.borderWidth = 1;
    passwordInput.layer.borderWidth = 1;

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
    
    emailInput.placeholder = brokerUsername[broker];
    
    if(self.addBroker == nil) {
        emailInput.text = self.tradeSession.authenticationInfo.id;
    }
    
    if(self.cancelToParent) {
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(home:)];
        self.navigationItem.leftBarButtonItem=newBackButton;
    }
    
    [pageTitle setText:[NSString stringWithFormat:@"Enter your %@ credentials to link your account and trade.", [TradeItTicket getBrokerDisplayString:broker]]];
    
    if([[TradeItTicket getLinkedBrokersList] containsObject:broker]){
        [self addUnlink];
    }
    
    [emailInput setDelegate:self];
    [passwordInput setDelegate:self];
}

-(void) addUnlink {
    unlinkButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [unlinkButton addTarget:self
               action:@selector(unlinkAccountPressed:)
     forControlEvents:UIControlEventTouchUpInside];
    [unlinkButton setTitle:@"Unlink Account" forState:UIControlStateNormal];
    [unlinkButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSLayoutConstraint * topConstraint = [NSLayoutConstraint
                                             constraintWithItem:unlinkButton
                                             attribute:NSLayoutAttributeTop
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:passwordInput
                                             attribute:NSLayoutAttributeBottom
                                             multiplier:1
                                             constant:32];
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
    
    if(self.tradeSession.errorTitle) {
        UIAlertView * alert;
        alert = [[UIAlertView alloc] initWithTitle:self.tradeSession.errorTitle message:self.tradeSession.errorMessage delegate: self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
        self.tradeSession.errorMessage = nil;
        self.tradeSession.errorTitle = nil;
    }
}


-(void)home:(UIBarButtonItem *)sender {
    [TradeItTicket returnToParentApp:self.tradeSession];
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
        
        UIAlertView * alert;
        alert = [[UIAlertView alloc] initWithTitle:@"Invalid Credentials" message:message delegate: self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    } else {
        [self performSegueWithIdentifier: @"loginToLoading" sender: self];
    }
}

-(IBAction) unlinkAccountPressed:(id) sender{
    NSString * broker = self.addBroker == nil ? self.tradeSession.broker : self.addBroker;
    
    [TradeItTicket storeUsername:@"" andPassword:@"" forBroker:broker];
    [TradeItTicket removeLinkedBroker: broker];
    
    if([self.tradeSession.broker isEqualToString:broker]) {
        self.tradeSession.broker = nil;
        self.tradeSession.authenticationInfo.id = @"";
        self.tradeSession.authenticationInfo.password = @"";
    }
    
    [TradeItTicket restartTicket:self.tradeSession];
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
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.35f];
    
    CGRect frame = self.view.frame;
    frame.origin.y = -125;
    [self.view setFrame:frame];
    
    [UIView commitAnimations];
    
    return YES;
}

-(BOOL) textFieldShouldEndEditing:(UITextField *)textField {
    //reverting the animation seems to blow up the page
    
    //might need to resign first responders in here
    
    //[UIView beginAnimations:nil context:NULL];
    //[UIView setAnimationDuration:0.35f];
    
    //CGRect frame = self.view.frame;
    //frame.origin.y = 150;
    //[self.view setFrame:frame];
    
    //[UIView commitAnimations];
    
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

@end

















