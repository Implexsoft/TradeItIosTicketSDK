//
//  TTSDKAccountLinkViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/13/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountLinkViewController.h"
#import "TTSDKTicketController.h"
#import "TTSDKUtils.h"

@interface TTSDKAccountLinkViewController () {
    TTSDKTicketController * globalController;
    TTSDKUtils * utils;
}

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property TTSDKUtils * sharedUtils;

@property NSArray * testingData;

@end

@implementation TTSDKAccountLinkViewController

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    utils = [TTSDKUtils sharedUtils];
    globalController = [TTSDKTicketController globalController];

    [utils styleMainActiveButton:self.doneButton];

    self.testingData = @[
                         [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Fidelity",@"broker",
                          @"Fidelity*7221",@"accountName",
                          @"Brokerage",@"accountType",
                          @"$12,340",@"buyingPower",
                          @"1",@"linked",
                          nil],
                         [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Robinhood",@"broker",
                          @"Robinhood*3748",@"accountName",
                          @"IRA",@"accountType",
                          @"$642",@"buyingPower",
                          @"0",@"linked",
                          nil]
                         ];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return globalController.accounts.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * cellIdentifier = @"AccountLink";
    TTSDKAccountLinkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [cell setDelegate: self];

    if (cell == nil) {
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
        NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];

        [tableView registerNib:[UINib nibWithNibName:@"TTSDKAccountLinkCell" bundle:resourceBundle] forCellReuseIdentifier:cellIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    }

    [cell configureCellWithData: (NSDictionary *)[globalController.accounts objectAtIndex:indexPath.row]];

    return cell;
}

- (void)linkToggleDidSelect:(NSDictionary *)account {
    NSNumber * active = [account valueForKey: @"active"];
    NSMutableArray * mutableAccounts = [globalController.accounts mutableCopy];

    int i;
    for (i = 0; i < mutableAccounts.count; i++) {
        NSMutableDictionary * acct = [[mutableAccounts objectAtIndex: i] mutableCopy];

        if ([acct isEqualToDictionary: account]) {
            [acct setValue: [NSNumber numberWithBool:!active] forKey:@"active"];

            [mutableAccounts setObject:acct atIndexedSubscript:i];

            break;
        }
    }

    globalController.accounts = [mutableAccounts copy];
}

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneBarButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}


@end
