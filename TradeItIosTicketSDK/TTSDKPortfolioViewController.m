//
//  TTSDKPortfolioViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/5/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioViewController.h"
#import "TTSDKPortfolioService.h"
#import "TradeItAuthenticationResult.h"
#import "TTSDKAccountsHeaderView.h"
#import "TTSDKHoldingsHeaderView.h"
#import "TTSDKLoginViewController.h"
#import "TradeItQuotesResult.h"
#import "TTSDKBrokerSelectViewController.h"

@interface TTSDKPortfolioViewController () {
    TTSDKPortfolioService * portfolioService;
    NSArray * accountsHolder;
    NSArray * positionsHolder;
    BOOL initialAuthenticationComplete;
    BOOL initialSummaryComplete;
}

@property (weak, nonatomic) IBOutlet UITableView *accountsTable;
@property NSInteger selectedHoldingIndex;
@property NSInteger selectedAccountIndex;
@property TTSDKAccountsHeaderView * accountsHeaderNib;
@property TTSDKHoldingsHeaderView * holdingsHeaderNib;
@property NSString * holdingsHeaderTitle;
@property UIView * accountsFooterView;

@end

@implementation TTSDKPortfolioViewController


#pragma mark Constants

static float kAccountsHeaderHeight = 165.0f;
static float kHoldingsHeaderHeight = 75.0f;
static float kHoldingCellDefaultHeight = 60.0f;
static float kHoldingCellExpandedHeight = 132.0f;
static float kAccountCellHeight = 44.0f;


#pragma mark Initialization

-(void) viewDidLoad {
    [super viewDidLoad];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];

    accountsHolder = [[NSArray alloc] init];
    positionsHolder = [[NSArray alloc] init];

    self.holdingsHeaderTitle = @"My Holdings";
    self.selectedHoldingIndex = -1;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!portfolioService || self.ticket.linkedAccounts.count != portfolioService.accounts.count) {
        portfolioService = nil;
        portfolioService = [[TTSDKPortfolioService alloc] initWithAccounts: self.ticket.linkedAccounts];
    }

    if (!self.ticket.currentSession.isAuthenticated) {
        [self showLoadingAndWait];

        [self.ticket.currentSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * res) {
            initialAuthenticationComplete = YES;
            if ([res.status isEqualToString: @"SUCCESS"]) {
                [self loadPortfolioData];
            } else {
                initialSummaryComplete = YES;
                if ([res isKindOfClass:TradeItErrorResult.class]) {
                    TradeItErrorResult * error = (TradeItErrorResult *)res;

                    [self showErrorAlert:error onAccept:^(void){
                        [self performSelectorOnMainThread:@selector(addAccountPressed:) withObject:self waitUntilDone:NO];
                    }];
                } else {
                    [self performSelectorOnMainThread:@selector(addAccountPressed:) withObject:self waitUntilDone:NO];
                }
            }
        }];
    } else {
        [self loadPortfolioData];
    }
}

-(void)loadPortfolioData {
    [portfolioService retrieveInitialSelectedAccount];

    self.selectedAccountIndex = [portfolioService.accounts indexOfObject:portfolioService.selectedAccount];

    self.holdingsHeaderTitle = [NSString stringWithFormat:@"%@ Holdings", portfolioService.selectedAccount.displayTitle];

    [portfolioService getSummaryForAccounts:^(void) {
        initialSummaryComplete = YES;

        accountsHolder = portfolioService.accounts;
        positionsHolder = [portfolioService filterPositionsByAccount: portfolioService.selectedAccount];

        [self.accountsTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];
}

-(void) showLoadingAndWait {
    TTSDKMBProgressHUD * hud = [TTSDKMBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Authenticating";

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        int cycles = 0;

        while((!initialAuthenticationComplete || !initialSummaryComplete) && cycles < 40) {
            if (initialAuthenticationComplete) {
                hud.labelText = @"Retrieving Account Summary";
            }
            [NSThread sleepForTimeInterval:0.25f];
            cycles++;
        }

        if(!initialAuthenticationComplete || !initialSummaryComplete) {
            if(![UIAlertController class]) {
                [self showOldErrorAlert:@"An Error Has Occurred" withMessage:@"TradeIt is temporarily unavailable. Please try again in a few minutes."];
                return;
            }
            
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"An Error Has Occurred"
                                                                            message:@"TradeIt is temporarily unavailable. Please try again in a few minutes."
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            alert.modalPresentationStyle = UIModalPresentationPopover;
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       [self.ticket returnToParentApp];
                                                                   }];
            [alert addAction:defaultAction];

            dispatch_async(dispatch_get_main_queue(), ^{
                [TTSDKMBProgressHUD hideHUDForView:self.view animated:YES];
                [self presentViewController:alert animated:YES completion:nil];

                UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
                alertPresentationController.sourceView = self.view;
                alertPresentationController.permittedArrowDirections = 0;
                alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
            });
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [TTSDKMBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }
    });
}

-(NSNumber *)retrieveTotalPortfolioValue {
    float totalPortfolioValue = 0.0f;

    for (TTSDKPortfolioAccount * portfolioAccount in accountsHolder) {
        totalPortfolioValue += [portfolioAccount.balance.totalValue floatValue];
    }

    return [NSNumber numberWithFloat:totalPortfolioValue];
}


#pragma mark Table Delegate Methods

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return accountsHolder.count;
    } else {
        return positionsHolder.count;
    }
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]];
    NSArray * headerArray;

    if (section == 0) {
        if (!self.accountsHeaderNib) {
            headerArray = [resourceBundle loadNibNamed:@"TTSDKAccountsHeader" owner:self options:nil];
            self.accountsHeaderNib = (TTSDKAccountsHeaderView *)[headerArray firstObject];

            UITapGestureRecognizer * editTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(editAccountsPressed:)];
            [self.accountsHeaderNib.editAccountsButton addGestureRecognizer: editTap];
        }

        [self.accountsHeaderNib populateTotalPortfolioValue: [self retrieveTotalPortfolioValue]];
        
        return self.accountsHeaderNib;

    } else {
        if (!self.holdingsHeaderNib) {
            headerArray = [resourceBundle loadNibNamed:@"TTSDKHoldingsHeader" owner:self options:nil];
            self.holdingsHeaderNib = (TTSDKHoldingsHeaderView *)[headerArray firstObject];
        }

        self.holdingsHeaderNib.holdingsHeaderTitle.text = self.holdingsHeaderTitle;

        return self.holdingsHeaderNib;
    }
}

-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {

    if (section == 0) {
        if (!self.accountsFooterView) {
            UIView * footerView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, tableView.frame.size.width, 70.0f)];
            footerView.backgroundColor = self.styles.pageBackgroundColor;
            
            NSString * buttonTitle = @"Add Account";

            CGSize buttonSize = [buttonTitle sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.0f]}];

            UIButton * linkButton = [[UIButton alloc] initWithFrame:CGRectMake(15.0f, buttonSize.height / 2.0f, tableView.frame.size.width, buttonSize.height)];
            [linkButton setTitle:buttonTitle forState:UIControlStateNormal];
            linkButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

            [linkButton setTitleColor:self.styles.activeColor forState:UIControlStateNormal];
            linkButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];

            [footerView addSubview:linkButton];

            UITapGestureRecognizer * linkTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addAccountPressed:)];
            [linkButton addGestureRecognizer: linkTap];

            self.accountsFooterView = footerView;
        }

        return self.accountsFooterView;
    } else {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
}

-(IBAction)addAccountPressed:(id)sender {
    [self performSegueWithIdentifier:@"PortfolioToLogin" sender:self];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return kAccountsHeaderHeight;
    } else {
        return kHoldingsHeaderHeight;
    }
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * cellIdentifier;
    NSString * nibIdentifier;
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]];

    if (indexPath.section == 0) {
        cellIdentifier = @"PortfolioAccountIdentifier";
        nibIdentifier = @"TTSDKPortfolioAccountCell";
        TTSDKPortfolioAccountsTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName: nibIdentifier bundle:resourceBundle] forCellReuseIdentifier:cellIdentifier];
            cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
        }

        cell.delegate = self;

        if (indexPath.row == 0) {
            [cell hideSeparator];
        } else {
            [cell showSeparator];
        }

        TTSDKPortfolioAccount * acct = [accountsHolder objectAtIndex: indexPath.row];
        [cell configureCellWithAccount: acct];

        BOOL selected = [portfolioService.selectedAccount.accountNumber isEqualToString: acct.accountNumber];
        [cell configureSelectedState: selected];

        return cell;
    } else {
        cellIdentifier = @"PortfolioHoldingIdentifier";
        nibIdentifier = @"TTSDKPortfolioHoldingCell";
        TTSDKPortfolioHoldingTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName: nibIdentifier bundle:resourceBundle] forCellReuseIdentifier:cellIdentifier];
            cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
        }

        cell.clipsToBounds = YES;
        cell.delegate = self;

        if (indexPath.row == 0) {
            [cell hideSeparator];
        } else {
            [cell showSeparator];
        }

        [cell configureCellWithPosition: [positionsHolder objectAtIndex: indexPath.row]];

        if (self.selectedHoldingIndex == indexPath.row) {
            cell.expandedView.hidden = NO;
        } else {
            cell.expandedView.hidden = YES;
        }

        return cell;
    }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row != self.selectedAccountIndex) {
            self.selectedAccountIndex = indexPath.row;
            TTSDKPortfolioAccount * selectedAccount = [accountsHolder objectAtIndex:indexPath.row];

            [portfolioService selectAccount: selectedAccount.accountNumber];
            positionsHolder = [portfolioService filterPositionsByAccount: selectedAccount];

            if (selectedAccount.displayTitle) {
                self.holdingsHeaderTitle = [NSString stringWithFormat:@"%@ Holdings", selectedAccount.displayTitle];
            } else {
                self.holdingsHeaderTitle = [NSString stringWithFormat:@"Holdings"];
            }

            [self updateTableContentSize];
            [self.accountsTable reloadData];
        }
    } else {
        if (indexPath.row == self.selectedHoldingIndex) {
            // User taps expanded row
            self.selectedHoldingIndex = -1;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else if (self.selectedHoldingIndex != -1) {
            // User taps different row
            NSIndexPath * prevPath = [NSIndexPath indexPathForRow: self.selectedHoldingIndex inSection: 1];
            self.selectedHoldingIndex = indexPath.row;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:prevPath] withRowAnimation:UITableViewRowAnimationFade];
            [self retrieveQuoteDataForPosition:[positionsHolder objectAtIndex:indexPath.row]];
        } else {
            // User taps new row with none expanded
            self.selectedHoldingIndex = indexPath.row;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self retrieveQuoteDataForPosition:[positionsHolder objectAtIndex:indexPath.row]];
        }

        [self updateTableContentSize];
        [self.accountsTable layoutIfNeeded];
    }
}

-(void) retrieveQuoteDataForPosition:(TTSDKPosition *)position {
    [portfolioService getQuoteForPosition:position withCompletionBlock:^(TradeItResult * res) {
        if ([res isKindOfClass:TradeItQuotesResult.class]) {
            TradeItQuotesResult * result = (TradeItQuotesResult *)res;
            position.quote = [[TradeItQuote alloc] initWithQuoteData:[result.quotes objectAtIndex:0]];
            [self.accountsTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        }
    }];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (UITableViewRowAction.class) {
        if (indexPath.section == 0) {
            return NO;
        } else if (indexPath.row == self.selectedHoldingIndex) {
            return NO;
        }

        return YES;
    } else {
        return NO;
    }
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (UITableViewRowAction.class && indexPath.section == 1) {

        UITableViewRowAction *buyAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"BUY" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            [tableView setEditing:NO];
            [self performSelector:@selector(didSelectBuy:) withObject:[positionsHolder objectAtIndex:indexPath.row] afterDelay:0];
        }];
        buyAction.backgroundColor = [UIColor colorWithRed:43.0f/255.0f green:100.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
        

        UITableViewRowAction *sellAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"SELL" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
            [tableView setEditing:NO];
            [self performSelector:@selector(didSelectSell:) withObject:[positionsHolder objectAtIndex:indexPath.row] afterDelay:0];
        }];
        sellAction.backgroundColor = [UIColor colorWithRed:88.0f/255.0f green:163.0f/255.0f blue:255.0f/255.0f alpha:1.0f];


        return @[sellAction, buyAction];
    } else {
        [tableView setEditing:NO];
        return nil;
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    // nothing to do, but must be implemented
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return kAccountCellHeight;
    } else {
        if (self.selectedHoldingIndex == indexPath.row) {
            return kHoldingCellExpandedHeight;
        } else {
            return kHoldingCellDefaultHeight;
        }
    }
}


#pragma mark Custom Delegate Methods

-(void)didSelectBuy:(TTSDKPosition *)position {
    self.ticket.previewRequest.orderAction = @"buy";
    [self updateQuoteByPosition: position];

    [[self.tabBarController.tabBar.items objectAtIndex:0] setEnabled: YES];
    [self.tabBarController setSelectedIndex: 0];
}

-(void)didSelectSell:(TTSDKPosition *)position {
    self.ticket.previewRequest.orderAction = @"sell";
    [self updateQuoteByPosition: position];
    

    [[self.tabBarController.tabBar.items objectAtIndex:0] setEnabled: YES];
    [self.tabBarController setSelectedIndex: 0];
}

-(void) updateQuoteByPosition:(TTSDKPosition *)position {
    TradeItQuote * quote = [[TradeItQuote alloc] init];
    quote.symbol = position.symbol;
    quote.companyName = position.companyName;
    self.ticket.quote = quote;
    self.ticket.previewRequest.orderSymbol = position.symbol;
}

-(void) didSelectAuth:(TTSDKPortfolioAccount *)account {
    NSDictionary * accountData = [account accountData];
    TTSDKTicketSession * accountSession = [self.ticket retrieveSessionByAccount: accountData];

    [accountSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * res){
        [self loadPortfolioData];
    }];
}


#pragma mark Custom UI

-(void)updateTableContentSize {
    CGRect contentRect = CGRectZero;

    for (UIView * view in [[self.accountsTable.subviews firstObject] subviews]) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }

    [self.accountsTable setContentSize:contentRect.size];
}


#pragma mark Navigation

- (IBAction)closePressed:(id)sender {
    [self.ticket returnToParentApp];
}

- (IBAction)editAccountsPressed:(id)sender {
    [self performSegueWithIdentifier:@"PortfolioToAccountLink" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PortfolioToLogin"]) {
        UINavigationController * dest = (UINavigationController *)[segue destinationViewController];
        
        UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];
        
        TTSDKBrokerSelectViewController * brokerSelectController = [ticket instantiateViewControllerWithIdentifier:@"BROKER_SELECT"];
        brokerSelectController.isModal = YES;
        
        [dest pushViewController:brokerSelectController animated:NO];
    }
}


@end
