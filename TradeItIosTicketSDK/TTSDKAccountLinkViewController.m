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
#import "TTSDKBrokerSelectViewController.h"

@interface TTSDKAccountLinkViewController () {
    TTSDKPortfolioService * portfolioService;
    BOOL noAccounts;
}
@property (weak, nonatomic) IBOutlet TTSDKPrimaryButton *addBrokerButton;
@property (weak, nonatomic) IBOutlet UITableView *linkTableView;
@property BOOL authenticated;

@end

@implementation TTSDKAccountLinkViewController

static NSString * kBrokerSelectViewIdentifier = @"BROKER_SELECT";

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

    [self.addBrokerButton activate];

    UITapGestureRecognizer * addBrokerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addBrokerButtonPressed:)];
    [self.addBrokerButton addGestureRecognizer: addBrokerTap];
}

-(void) viewWillAppear:(BOOL)animated {
    portfolioService = [TTSDKPortfolioService serviceForAllAccounts];

    if (!self.ticket.currentSession.isAuthenticated) {
        [self.ticket.currentSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult *result) {
            [self loadBalances];
        }];
    } else {
        [self loadBalances];
    }
}

-(void) loadBalances {
    [portfolioService getBalancesForAccounts:^(void) {
        [self.linkTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];
}


#pragma mark Table Delegate Methods

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0f;
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

    // Unlinking account, so check whether it's the last account for a login
    BOOL isUnlinkingBroker = NO;
    if (!toggle.on) {
        int accountsToUnlink;

        for (TTSDKPortfolioAccount * portfolioAccount in portfolioService.accounts) {
            if ([portfolioAccount.userId isEqualToString: account.userId] && portfolioAccount.active) {
                accountsToUnlink++;
            }
        }

        isUnlinkingBroker = accountsToUnlink < 2;
    }

    if (isUnlinkingBroker) {
        // This is a bit weird, but prevents unnecessary complexity for showing alerts
        TradeItErrorResult * error = [[TradeItErrorResult alloc] init];
        error.shortMessage = [NSString stringWithFormat:@"Unlink %@", account.broker];
        error.longMessages = @[ [NSString stringWithFormat:@"Deselecting all the accounts for %@ will automatically delete this broker and its associated data.", account.broker], @"Tap \"Add Broker\" to bring it back"];

        // Prompt the user to either login or cancel the unlink action
        [self showErrorAlert:error onAccept:^(void){
            [self toggleAccount: account];

            [portfolioService deleteAccounts: account.userId];

            [self.linkTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];

            if ([portfolioService linkedAccountsCount] < 1) {
                noAccounts = YES;
                [self performSegueWithIdentifier:@"AccountLinkToLogin" sender:self];
            }
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

-(IBAction) addBrokerButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"AccountLinkToLogin" sender:self];
}

-(IBAction) doneBarButtonPressed:(id)sender {
    if (self.ticket.presentationMode == TradeItPresentationModeAccounts) {
        [self.ticket returnToParentApp];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AccountLinkToLogin"]) {
        UINavigationController * nav = (UINavigationController *)segue.destinationViewController;
        TTSDKBrokerSelectViewController * brokerSelect = (TTSDKBrokerSelectViewController *) [nav.viewControllers objectAtIndex:0];
        brokerSelect.isModal = YES;
        if (noAccounts) {
            brokerSelect.closeToParent = YES;
        }
    }
}


@end
