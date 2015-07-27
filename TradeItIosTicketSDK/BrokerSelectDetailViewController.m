//
//  BrokerSelectDetailViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "BrokerSelectDetailViewController.h"

@implementation BrokerSelectDetailViewController {
    
    __weak IBOutlet UIImageView *logo;
    __weak IBOutlet UITextField *emailInput;
    __weak IBOutlet UITextField *passwordInput;
    
    NSDictionary * brokerUsername;
}

-(void) viewDidLoad {
    UIImage * image = [UIImage imageNamed: [NSString stringWithFormat: @"TradeItIosTicketSDK.bundle/%@.png", self.tradeSession.broker]];
    logo.image = image;
    [logo setContentMode: UIViewContentModeScaleAspectFit];
    
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
    
    emailInput.placeholder = brokerUsername[self.tradeSession.broker];
    
    if(![self.tradeSession.authenticationInfo.id isEqualToString:@""]) {
        emailInput.text = self.tradeSession.authenticationInfo.id;
    }
    
    if(self.cancelToParent) {
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(home:)];
        self.navigationItem.leftBarButtonItem=newBackButton;
    }
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
    if(emailInput.text.length < 1 || passwordInput.text.length < 1) {
        NSString * message = [NSString stringWithFormat:@"Please enter a %@ and password.", brokerUsername[self.tradeSession.broker]];
        
        UIAlertView * alert;
        alert = [[UIAlertView alloc] initWithTitle:@"Invalid Credentials" message:message delegate: self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    } else {
        self.tradeSession.authenticationInfo = [[TradeItAuthenticationInfo alloc]initWithId:emailInput.text andPassword:passwordInput.text];
        [self performSegueWithIdentifier: @"loginToLoading" sender: self];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [[segue destinationViewController] setActionToPerform: @"verifyCredentials"];
    [[segue destinationViewController] setTradeSession: self.tradeSession];
}

@end
