//
//  TTSDKPortfolioViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/5/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioViewController.h"
#import "TTSDKTradeItTicket.h"
#import "TTSDKUtils.h"
#import "TTSDKPortfolioService.h"
#import "TradeItAuthenticationResult.h"
#import "TTSDKAccountsHeaderView.h"
#import "TTSDKHoldingsHeaderView.h"
#import "TTSDKLoginViewController.h"

@interface TTSDKPortfolioViewController () {
    TTSDKTradeItTicket * globalTicket;
    TTSDKUtils * utils;
    TTSDKPortfolioService * portfolioService;
    NSArray * accountsHolder;
    NSArray * positionsHolder;
}

@property (weak, nonatomic) IBOutlet UITableView *accountsTable;
@property NSInteger selectedIndex;
@property UIView * loadingView;
@property TTSDKAccountsHeaderView * accountsHeaderNib;
@property TTSDKHoldingsHeaderView * holdingsHeaderNib;

@property TTSDKPortfolioAccount * accountToPerformManualAuth;

@end

@implementation TTSDKPortfolioViewController



#pragma mark - Constants

static float kAccountsHeaderHeight = 165.0f;
static float kHoldingsHeaderHeight = 75.0f;
static float kHoldingCellDefaultHeight = 60.0f;
static float kHoldingCellExpandedHeight = 132.0f;
static float kAccountCellHeight = 44.0f;



#pragma mark - Orientation

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}



#pragma mark - Initialization

-(void) viewDidLoad {
    utils = [TTSDKUtils sharedUtils];
    globalTicket = [TTSDKTradeItTicket globalTicket];

    accountsHolder = [[NSArray alloc] init];
    positionsHolder = [[NSArray alloc] init];

    if (!self.loadingView) {
        self.loadingView = [utils retrieveLoadingOverlayForView:self.view];
        [self.view addSubview:self.loadingView];
    }
    self.loadingView.hidden = NO;
    self.selectedIndex = -1;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    portfolioService = nil;
    portfolioService = [[TTSDKPortfolioService alloc] initWithAccounts: globalTicket.linkedAccounts];

    if (!globalTicket.currentSession.isAuthenticated) {
        [globalTicket.currentSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * res) {
            if ([res isKindOfClass:TradeItAuthenticationResult.class]) {
                [self loadPortfolioData];
            }
        }];
    } else {
        [self loadPortfolioData];
    }
}

-(void)loadPortfolioData {
    [portfolioService getSummaryForAccounts:^(void){
        self.loadingView.hidden = YES;
        accountsHolder = portfolioService.accounts;
        positionsHolder = [portfolioService positionsForAccounts];

        [portfolioService getQuotesForAccounts:^(void) {
            [self.accountsTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        }];

        [self.accountsTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];
}

-(NSNumber *)retrieveTotalPortfolioValue {
    float totalPortfolioValue = 0.0f;

    for (TTSDKPortfolioAccount * portfolioAccount in accountsHolder) {
        totalPortfolioValue += [portfolioAccount.balance.totalValue floatValue];
    }

    return [NSNumber numberWithFloat:totalPortfolioValue];
}



#pragma mark - Table Delegate Methods

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

        return self.holdingsHeaderNib;

    }
}

-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
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

        [cell configureCellWithAccount: [accountsHolder objectAtIndex: indexPath.row]];

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

        return cell;
    }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if (indexPath.row == self.selectedIndex) {
            // User taps expanded row
            self.selectedIndex = -1;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else if (self.selectedIndex != -1) {
            // User taps different row
            NSIndexPath * prevPath = [NSIndexPath indexPathForRow: self.selectedIndex inSection: 1];
            self.selectedIndex = indexPath.row;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:prevPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            // User taps new row with none expanded
            self.selectedIndex = indexPath.row;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }

    [self updateTableContentSize];
    [self.accountsTable layoutIfNeeded];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return kAccountCellHeight;
    } else {
        if (self.selectedIndex == indexPath.row) {
            return kHoldingCellExpandedHeight;
        } else {
            return kHoldingCellDefaultHeight;
        }
    }
}



#pragma mark - Custom Delegate Methods

-(void)didSelectBuy:(TTSDKPosition *)position {
    globalTicket.previewRequest.orderAction = @"buy";
    [self updateQuoteByPosition: position];

    [[self.tabBarController.tabBar.items objectAtIndex:0] setEnabled: YES];
    [self.tabBarController setSelectedIndex: 0];
}

-(void)didSelectSell:(TTSDKPosition *)position {
    globalTicket.previewRequest.orderAction = @"sell";
    [self updateQuoteByPosition: position];

    [[self.tabBarController.tabBar.items objectAtIndex:0] setEnabled: YES];
    [self.tabBarController setSelectedIndex: 0];
}

-(void) updateQuoteByPosition:(TTSDKPosition *)position {
    TradeItQuote * quote = [[TradeItQuote alloc] init];
    quote.symbol = position.symbol;
    quote.companyName = position.companyName;
    globalTicket.quote = quote;
    globalTicket.previewRequest.orderSymbol = position.symbol;
}

-(void) didSelectAuth:(TTSDKPortfolioAccount *)account {
    self.accountToPerformManualAuth = account;
    [self performSegueWithIdentifier: @"PortfolioToLogin" sender: self];
}



#pragma mark - Custom UI

-(void)updateTableContentSize {
    CGRect contentRect = CGRectZero;

    for (UIView * view in [[self.accountsTable.subviews firstObject] subviews]) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }

    [self.accountsTable setContentSize:contentRect.size];
}



#pragma mark - Navigation

- (IBAction)closePressed:(id)sender {
    [globalTicket returnToParentApp];
}

- (IBAction)editAccountsPressed:(id)sender {
    [self performSegueWithIdentifier:@"PortfolioToAccountLink" sender:self];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PortfolioToLogin"]) {

        // Get storyboard
        UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];

        UINavigationController * nav = (UINavigationController *)segue.destinationViewController;

        TTSDKLoginViewController * loginVC = [ticket instantiateViewControllerWithIdentifier:@"LOGIN"];

        loginVC.addBroker = self.accountToPerformManualAuth.broker;

        [nav pushViewController:loginVC animated:NO];
    }
}



@end
