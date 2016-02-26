//
//  TTSDKPortfolioViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/16/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountSelectViewController.h"
#import "TTSDKAccountSelectTableViewCell.h"
#import "TTSDKTradeViewController.h"
#import "TTSDKBrokerSelectViewController.h"
#import "TTSDKTradeItTicket.h"
#import "TTSDKUtils.h"
#import "TTSDKPortfolioService.h"
#import "TTSDKPortfolioAccount.h"

@interface TTSDKAccountSelectViewController () {
    TTSDKTradeItTicket * globalTicket;
    TTSDKUtils * utils;
    TTSDKPortfolioService * portfolioService;
    UIView * loadingView;
    NSArray * accountResults;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *editBrokersButton;

@end

@implementation TTSDKAccountSelectViewController

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}

-(void) viewDidLoad {
    [super viewDidLoad];

    utils = [TTSDKUtils sharedUtils];
    globalTicket = [TTSDKTradeItTicket globalTicket];

    if (!loadingView) {
        loadingView = [utils retrieveLoadingOverlayForView: self.view];
        [self.view addSubview:loadingView];
        loadingView.hidden = NO;
    }

    accountResults = [[NSArray alloc] init];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    portfolioService = [[TTSDKPortfolioService alloc] initWithAccounts: globalTicket.linkedAccounts];
    [portfolioService getSummaryForAccounts:^(void) {
        loadingView.hidden = YES;
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];

    [self.tableView reloadData];
}

-(IBAction) editBrokersPressed:(id)sender {
    [self performSegueWithIdentifier:@"AccountSelectToAccountLink" sender:self];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return portfolioService.accounts.count;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TTSDKPortfolioAccount * account = [portfolioService.accounts objectAtIndex: indexPath.row];

    NSDictionary * selectedAccount = [account accountData];
    globalTicket.currentAccount = selectedAccount;

    TTSDKTradeViewController * tradeVC = (TTSDKTradeViewController *)[self.navigationController.viewControllers objectAtIndex:0];
    [self.navigationController popToViewController:tradeVC animated: YES];
}

-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [self createFooterView];
}

-(UIView *) createFooterView {
    UIView * footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];

    UIButton * addAccount = [[UIButton alloc] initWithFrame:CGRectMake(footerView.frame.origin.x + 43, footerView.frame.origin.y, footerView.frame.size.width / 2, footerView.frame.size.height / 2)];
    [addAccount setTitle:@"Add Account" forState:UIControlStateNormal];
    addAccount.tintColor = [UIColor colorWithRed:0.00f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
    [addAccount setTitleColor:[UIColor colorWithRed:0.00f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    [addAccount.titleLabel setFont: [UIFont systemFontOfSize:15.0f]];
    addAccount.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [addAccount setUserInteractionEnabled:YES];

    UITapGestureRecognizer * addAccountTap = [[UITapGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(addAccountPressed:)];
    [addAccount addGestureRecognizer:addAccountTap];

    footerView.backgroundColor = [UIColor whiteColor];

    [footerView addSubview:addAccount];

    return footerView;
}

-(IBAction) addAccountPressed:(id)sender {
    [self performSegueWithIdentifier:@"AccountSelectToBrokerSelect" sender:self];
}

-(BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * accountIdentifier = @"AccountSelect";
    TTSDKAccountSelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:accountIdentifier];
    if (cell == nil) {
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
        NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];

        [tableView registerNib:[UINib nibWithNibName:@"TTSDKAccountSelectCell" bundle:resourceBundle] forCellReuseIdentifier:accountIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:accountIdentifier];
    }

    TTSDKPortfolioAccount * account = [portfolioService.accounts objectAtIndex: indexPath.row];
    [cell configureCellWithAccount: account];

    return cell;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AccountSelectToBrokerSelect"]) {
        UINavigationController * dest = (UINavigationController *)[segue destinationViewController];

        UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]]];

        TTSDKBrokerSelectViewController * brokerSelectController = [ticket instantiateViewControllerWithIdentifier:@"BROKER_SELECT"];
        brokerSelectController.isModal = YES;

        [dest pushViewController:brokerSelectController animated:NO];
    }
}



@end
