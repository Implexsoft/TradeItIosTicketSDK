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
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneBarButton;

@end

@implementation TTSDKAccountLinkViewController

static NSString * kBrokerSelectViewIdentifier = @"BROKER_SELECT";
static NSString * kLoginSegueIdentifier = @"AccountLinkToLogin";

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

-(void) setViewStyles {
    [super setViewStyles];

    if (self.pushed) {
        [self.doneBarButton setTintColor:[UIColor clearColor]];
    }

    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.doneButton.backgroundColor = self.styles.secondaryDarkActiveColor;
    self.doneButton.layer.cornerRadius = 5.0f;
}

-(void) viewWillAppear:(BOOL)animated {
    portfolioService = [TTSDKPortfolioService serviceForAllAccounts];

    [self.linkTableView reloadData];

    if (self.ticket.currentSession && !self.ticket.currentSession.isAuthenticated) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
        
        [self.ticket.currentSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * res) {
            [[self.tabBarController.tabBar.items objectAtIndex:1] setEnabled:YES];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
            if ([res isKindOfClass:TradeItAuthenticationResult.class]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loadBalances];
                });
            } else if ([res isKindOfClass:TradeItErrorResult.class]) {
                TradeItErrorResult * error = (TradeItErrorResult *)res;
                NSMutableString * errorMessage = [[NSMutableString alloc] init];
                
                for (NSString * str in error.longMessages) {
                    [errorMessage appendString:str];
                }
                
                if(![UIAlertController class]) {
                    [self showOldErrorAlert:error.shortMessage withMessage:errorMessage];
                } else {
                    UIAlertController * alert = [UIAlertController alertControllerWithTitle:error.shortMessage
                                                                                    message:errorMessage
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                    
                    alert.modalPresentationStyle = UIModalPresentationPopover;
                    
                    UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"Login" style:UIAlertActionStyleDefault
                                                                           handler:^(UIAlertAction * action) {
                                                                               [self performSegueWithIdentifier:kLoginSegueIdentifier sender:self];
                                                                           }];

                    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        [self.ticket returnToParentApp];
                    }];

                    [alert addAction:defaultAction];
                    [alert addAction:cancelAction];

                    [self presentViewController:alert animated:YES completion:nil];
                    
                    UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
                    alertPresentationController.sourceView = self.view;
                    alertPresentationController.permittedArrowDirections = 0;
                    alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
                }
                
            }
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
        int accountsToUnlink = 0;

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
                self.ticket.sessions = [[NSArray alloc] init]; // reset the sessions
                [self performSegueWithIdentifier:kLoginSegueIdentifier sender:self];
            }
        } onCancel:^(void) {
            toggle.on = YES;
        }];
    } else {
        [self toggleAccount: account];

        // Check to see if we're unlinking the current account. If so, auto-select another account
        if (!toggle.on && [account.accountNumber isEqualToString:[self.ticket.currentAccount valueForKey: @"accountNumber"]]) {
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
    [self performSegueWithIdentifier:kLoginSegueIdentifier sender:self];
}

- (IBAction)donePressed:(id)sender {
    if (self.ticket.presentationMode == TradeItPresentationModeAccounts) {
        [self.ticket returnToParentApp];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(IBAction) doneBarButtonPressed:(id)sender {
    if (self.ticket.presentationMode == TradeItPresentationModeAccounts) {
        [self.ticket returnToParentApp];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    if ([segue.identifier isEqualToString:kLoginSegueIdentifier]) {
        UINavigationController * nav = (UINavigationController *)segue.destinationViewController;
        TTSDKBrokerSelectViewController * brokerSelect = (TTSDKBrokerSelectViewController *) [nav.viewControllers objectAtIndex:0];
        brokerSelect.isModal = YES;
        if (noAccounts) {
            brokerSelect.closeToParent = YES;
        }
    }
}


@end
