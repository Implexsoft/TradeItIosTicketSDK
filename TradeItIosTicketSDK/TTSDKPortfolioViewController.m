//
//  TTSDKPortfolioViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/5/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioViewController.h"
#import "TTSDKTicketController.h"
#import "TTSDKUtils.h"
#import "TTSDKPortfolioHoldingTableViewCell.h"
#import "TTSDKPortfolioAccountsTableViewCell.h"
#import "TTSDKAccountService.h"
#import "TradeItAuthenticationResult.h"

@interface TTSDKPortfolioViewController () {
    TTSDKTicketController * globalController;
    TTSDKUtils * utils;
    NSArray * linkedAccounts;
    NSArray * linkedBalances;
    NSArray * linkedPositions;
    TTSDKAccountService * accountService;
}
@property (weak, nonatomic) IBOutlet UILabel *totalPortfolioValueLabel;

@property (weak, nonatomic) IBOutlet UIButton *editBrokersButton;
@property (weak, nonatomic) IBOutlet UIButton *doneEditingBrokersButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property NSArray * testAccounts;
@property NSArray * testHoldings;
@property (weak, nonatomic) IBOutlet UITableView *accountsTable;
@property (weak, nonatomic) IBOutlet UITableView *holdingsTable;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *holdingsHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *accountsHeightConstraint;

@property NSInteger selectedIndex;
@property (weak, nonatomic) IBOutlet UIButton *editAccountsButton;

@end

@implementation TTSDKPortfolioViewController



#pragma mark - Constants

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
    globalController = [TTSDKTicketController globalController];

    self.scrollView.scrollEnabled = YES;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.alwaysBounceHorizontal = NO;
    self.scrollView.bounces = YES;
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, [self.scrollView.subviews firstObject].frame.size.height);
    [self.scrollView needsUpdateConstraints];

    self.selectedIndex = -1;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!globalController.currentSession.isAuthenticated) {
        [globalController.currentSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * res) {
            if ([res isKindOfClass:TradeItAuthenticationResult.class]) {
                [self loadPortfolioData];
            }
        }];
    } else {
        [self loadPortfolioData];
    }
}

-(void)loadPortfolioData {
    linkedAccounts = [globalController retrieveLinkedAccounts];
    linkedPositions = [[NSArray alloc] init];
    
    accountService = [[TTSDKAccountService alloc] init];
    [accountService getAccountSummaryFromLinkedAccounts:^(TTSDKAccountSummaryResult * summary) {
        NSMutableArray * positionsHolder = [[NSMutableArray alloc] init];
        for (TTSDKPosition * position in summary.positions) {
            [positionsHolder addObject: position];
        }
        
        NSMutableArray * balancesHolder = [[NSMutableArray alloc] init];
        for (NSDictionary * balance in summary.balances) {
            [balancesHolder addObject: balance];
        }
        
        linkedPositions = [positionsHolder copy];
        linkedBalances = [balancesHolder copy];

        [self.holdingsTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        [self.accountsTable performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];
}



#pragma mark - Table Delegate Methods

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    tableView.alwaysBounceVertical = NO;
    tableView.scrollEnabled = NO;
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isHoldingsTable:tableView]) {
        return linkedPositions.count;
    } else {
        return linkedBalances.count;
    }
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * cellIdentifier;
    NSString * nibIdentifier;
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
    NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];

    if ([self isHoldingsTable:tableView]) {
        cellIdentifier = @"PortfolioHoldingIdentifier";
        nibIdentifier = @"TTSDKPortfolioHoldingCell";
        TTSDKPortfolioHoldingTableViewCell * cell = (TTSDKPortfolioHoldingTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName:nibIdentifier bundle:resourceBundle] forCellReuseIdentifier:cellIdentifier];
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        }

        [cell configureCellWithPosition: (TTSDKPosition *)[linkedPositions objectAtIndex: indexPath.row]];

        if (indexPath.row == 0) {
            [cell hideSeparator];
        } else {
            [cell showSeparator];
        }

        cell.clipsToBounds = YES;

        return cell;
    } else {
        cellIdentifier = @"PortfolioAccountIdentifier";
        nibIdentifier = @"TTSDKPortfolioAccountCell";
        TTSDKPortfolioAccountsTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

        if (cell == nil) {
            [tableView registerNib:[UINib nibWithNibName:nibIdentifier bundle:resourceBundle] forCellReuseIdentifier:cellIdentifier];
            cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        }

        [cell configureCellWithDetails:[linkedBalances objectAtIndex:indexPath.row]];

        return cell;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedIndex == indexPath.row) {
        // User taps expanded row
        self.selectedIndex = -1;
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (self.selectedIndex != -1) {
        // User taps different row
        NSIndexPath * prevPath = [NSIndexPath indexPathForRow:self.selectedIndex inSection:0];
        self.selectedIndex = indexPath.row;
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:prevPath] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        // User taps new row with none expanded
        self.selectedIndex = indexPath.row;
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }

    [self updateScrollContentSize:tableView];
    [self resizeUIComponents];

    [tableView layoutIfNeeded];
    [tableView setNeedsUpdateConstraints];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isHoldingsTable:tableView]) {
        if (self.selectedIndex == indexPath.row) {
            return kHoldingCellExpandedHeight;
        } else {
            return kHoldingCellDefaultHeight;
        }
    } else {
        return kAccountCellHeight;
    }
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        [self resizeUIComponents];
    }
}



#pragma mark - Custom UI

-(void) resizeUIComponents {
    self.holdingsHeightConstraint.constant = self.holdingsTable.contentSize.height;
    self.accountsHeightConstraint.constant = self.accountsTable.contentSize.height;

    [self updateScrollContentSize:self.scrollView];

    [self.scrollView layoutIfNeeded];
    [self.scrollView setNeedsUpdateConstraints];
    [self.scrollView layoutSubviews];
}

-(void)updateScrollContentSize:(UIScrollView *)scrollView {
    CGRect contentRect = CGRectZero;

    for (UIView * view in [[scrollView.subviews firstObject] subviews]) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }

    [scrollView setContentSize:contentRect.size];
}

-(BOOL) isHoldingsTable:(UITableView *)tableView {
    // the accounts table tag is 0 and the holdings table tag is 1
    return tableView.tag == 1;
}



#pragma mark - Navigation

- (IBAction)closePressed:(id)sender {
    [globalController returnToParentApp];
}

- (IBAction)editAccountsPressed:(id)sender {
    [self performSegueWithIdentifier:@"PortfolioToAccountLink" sender:self];
}



@end
