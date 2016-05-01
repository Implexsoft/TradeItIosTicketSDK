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

    [self.doneButton activate];
}

-(void) viewWillAppear:(BOOL)animated {
    //portfolioService = [[TTSDKPortfolioService alloc] initWithAccounts: self.ticket.allAccounts];
    portfolioService = [TTSDKPortfolioService serviceForAllAccounts];

    [portfolioService getBalancesForAccounts:^(void) {
        [self.linkTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];
}


#pragma mark Table Delegate Methods

-(BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(NSArray<UITableViewRowAction *> *) tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction * deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"DELETE" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {

        TTSDKPortfolioAccount * portfolioAccount = [portfolioService.accounts objectAtIndex: indexPath.row];
        [portfolioService deleteAccount: portfolioAccount];

        [self.linkTableView beginUpdates];
        [self.linkTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
        [self.linkTableView endUpdates];
    }];

    return @[deleteAction];
}

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

-(void) linkToggleDidSelect:(UISwitch *)toggle forAccount:(TTSDKPortfolioAccount *)account {
    // Check to see if we're unlinking the last account
    if (!toggle.on && self.ticket.linkedAccounts.count == 1) {

        // This is a bit weird, but prevents unnecessary complexity for showing alerts
        TradeItErrorResult * error = [[TradeItErrorResult alloc] init];
        error.shortMessage = @"Unlinking last account";
        error.longMessages = @[@"Please login with another account to continue trading."];

        // Prompt the user to either login or cancel the unlink action
        [self showErrorAlert:error onAccept:^(void){
            [self toggleAccount: account];
            [self performSegueWithIdentifier:@"AccountLinkToLogin" sender:self];
        } onCancel:^(void) {
            toggle.on = YES;
        }];

    } else {
        [self toggleAccount: account];

        // Check to see if we're unlinking the current account. If so, auto-select another account
        if ([account.accountNumber isEqualToString:[self.ticket.currentAccount valueForKey: @"accountNumber"]]) {
            TTSDKPortfolioAccount * newSelectedAccount = [portfolioService retrieveAutoSelectedAccount];
            NSDictionary * newAcctData = [newSelectedAccount accountData];
            if (![newSelectedAccount.userId isEqualToString:self.ticket.currentSession.login.userId]) {
                [self.ticket selectCurrentSession:[self.ticket retrieveSessionByAccount: newAcctData] andAccount:newAcctData];
            } else {
                [self.ticket selectCurrentAccount: newAcctData];
            }
        }
    }
}

-(void) toggleAccount:(TTSDKPortfolioAccount *)account {
    [portfolioService toggleAccount: account];
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

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AccountLinkToLogin"]) {
        UINavigationController * nav = (UINavigationController *)segue.destinationViewController;
        [self.ticket removeOnboardingFromNav:nav];
    }
}



@end
