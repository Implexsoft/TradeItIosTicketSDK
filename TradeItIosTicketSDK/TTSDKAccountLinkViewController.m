//
//  TTSDKAccountLinkViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/13/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountLinkViewController.h"
#import "TTSDKPortfolioService.h"
#import "TTSDKPortfolioAccount.h"
#import "TTSDKPrimaryButton.h"

@interface TTSDKAccountLinkViewController () {
    TTSDKPortfolioService * portfolioService;
}

@property (weak, nonatomic) IBOutlet TTSDKPrimaryButton *doneButton;
@property (weak, nonatomic) IBOutlet UITableView *linkTableView;

@end

@implementation TTSDKAccountLinkViewController


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

    portfolioService = [[TTSDKPortfolioService alloc] initWithAccounts: self.ticket.allAccounts];

    [self.doneButton activate];
}

-(void) viewWillAppear:(BOOL)animated {
    [portfolioService getBalancesForAccounts:^(void) {
        [self.linkTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];
}


#pragma mark Table Delegate Methods

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return portfolioService.accounts.count;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * cellIdentifier = @"AccountLink";
    TTSDKAccountLinkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
        NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];

        [tableView registerNib:[UINib nibWithNibName:@"TTSDKAccountLinkCell" bundle:resourceBundle] forCellReuseIdentifier:cellIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    }

    [cell setDelegate: self];

    [cell configureCellWithAccount: [portfolioService.accounts objectAtIndex: indexPath.row]];

    return cell;
}


#pragma mark Custom Delegate Methods

-(void) linkToggleDidSelect:(UISwitch *)toggle forAccount:(NSDictionary *)account {
    if (!self.ticket.linkedAccounts.count) {
        
        NSString * errorTitle = @"No linked accounts";
        NSString * errorMessage = @"Login with another account to continue trading";
        
        if(![UIAlertController class]) {
            [self showOldErrorAlert: errorTitle withMessage:errorMessage];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle: errorTitle
                                                                            message: errorMessage
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            
            alert.modalPresentationStyle = UIModalPresentationPopover;
            
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       [self toggleAccount: account];
                                                                   }];

            UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                BOOL active = [[account valueForKey: @"active"] boolValue];
                toggle.on = active;
            }];

            [alert addAction:defaultAction];
            [alert addAction:cancelAction];
            [self presentViewController:alert animated:YES completion:nil];
            
            UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
            alertPresentationController.sourceView = self.view;
            alertPresentationController.permittedArrowDirections = 0;
            alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
        }
    } else {
        [self toggleAccount: account];
    }
}

-(void) toggleAccount:(NSDictionary *)account {
    BOOL active = [[account valueForKey: @"active"] boolValue];

    NSDictionary * accountToAdd;
    NSDictionary * accountToRemove;
    
    NSArray * accounts = self.ticket.allAccounts;
    
    int i;
    for (i = 0; i < accounts.count; i++) {
        NSDictionary * currentAccount = [accounts objectAtIndex: i];
        
        NSString * currentAccountNumber = [currentAccount valueForKey: @"accountNumber"];
        NSString * accountNumber = [account valueForKey: @"accountNumber"];
        
        if ([currentAccountNumber isEqualToString: accountNumber]) {
            NSMutableDictionary *mutableAccount = [currentAccount mutableCopy];
            [mutableAccount setValue:[NSNumber numberWithBool: !active] forKey:@"active"];
            accountToAdd = [mutableAccount copy];
            accountToRemove = currentAccount;
        }
    }
    
    NSMutableArray * mutableAccounts = [accounts mutableCopy];
    [mutableAccounts removeObject: accountToRemove];
    [mutableAccounts addObject: accountToAdd];
    
    [self.ticket saveAccountsToUserDefaults: [mutableAccounts copy]];
}

-(void) linkToggleDidNotSelect:(NSString *)errorMessage {
    NSString * errorTitle = @"Unable to unlink account";
    if(![UIAlertController class]) {
        [self showOldErrorAlert: errorTitle withMessage:errorMessage];
    } else {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle: errorTitle
                                                                        message: errorMessage
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


#pragma mark Navigation

-(IBAction) doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction) doneBarButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
