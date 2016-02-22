//
//  TTSDKAccountLinkViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/13/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountLinkViewController.h"
#import "TTSDKTradeItTicket.h"
#import "TTSDKUtils.h"
#import "TTSDKPortfolioService.h"
#import "TTSDKPortfolioAccount.h"

@interface TTSDKAccountLinkViewController () {
    TTSDKTradeItTicket * globalTicket;
    TTSDKUtils * utils;
    UIView * loadingView;
    TTSDKPortfolioService * portfolioService;
}

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITableView *linkTableView;

@end

@implementation TTSDKAccountLinkViewController



#pragma mark - Rotation

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}



#pragma mark - Initialization

-(void) viewDidLoad {
    [super viewDidLoad];

    utils = [TTSDKUtils sharedUtils];
    globalTicket = [TTSDKTradeItTicket globalTicket];

    portfolioService = [[TTSDKPortfolioService alloc] initWithAccounts: globalTicket.allAccounts];

    [utils styleMainActiveButton:self.doneButton];

    loadingView = [utils retrieveLoadingOverlayForView:self.view];
    [self.view addSubview:loadingView];
}

-(void) viewWillAppear:(BOOL)animated {
    loadingView.hidden = NO;

    [portfolioService getBalancesForAccounts:^(void) {
        loadingView.hidden = YES;

        [self.linkTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];
}



#pragma mark - Table Delegate Methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return portfolioService.accounts.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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



#pragma mark - Custom Delegate Methods

- (void)linkToggleDidSelect:(NSDictionary *)account {
    BOOL active = [[account valueForKey: @"active"] boolValue];

    NSDictionary * accountToAdd;
    NSDictionary * accountToRemove;

    NSArray * accounts = globalTicket.allAccounts;
    int i;
    for (i = 0; i < accounts.count; i++) {
        NSDictionary * currentAccount = [accounts objectAtIndex: i];

        if ([currentAccount isEqualToDictionary:account]) {
            NSMutableDictionary *mutableAccount = [currentAccount mutableCopy];
            [mutableAccount setValue:[NSNumber numberWithBool: !active] forKey:@"active"];
            accountToAdd = [mutableAccount copy];
            accountToRemove = currentAccount;
        }
    }

    NSMutableArray * mutableAccounts = [accounts mutableCopy];
    [mutableAccounts removeObject: accountToRemove];
    [mutableAccounts addObject: accountToAdd];

    [globalTicket saveAccountsToUserDefaults: [mutableAccounts copy]];
}

- (void)linkToggleDidNotSelect:(NSString *)errorMessage {
    NSString * errorTitle = @"Unable to unlink account";
    if(![UIAlertController class]) {
        [self showOldErrorAlert: errorTitle withMessage:errorMessage];
    } else {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle: errorTitle
                                                                        message: errorMessage
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}



#pragma mark - Navigation

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneBarButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - iOS 7 Fallbacks

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}



@end
