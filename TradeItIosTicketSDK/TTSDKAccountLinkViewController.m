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

- (void)viewDidLoad {
    [super viewDidLoad];

    utils = [TTSDKUtils sharedUtils];
    globalController = [TTSDKTicketController globalController];

    [utils styleMainActiveButton:self.doneButton];
}



#pragma mark - Table Delegate Methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return globalController.accounts.count;
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

    [cell configureCellWithData: (NSDictionary *)[globalController.accounts objectAtIndex:indexPath.row]];

    return cell;
}



#pragma mark - Custom Delegate Methods

- (void)linkToggleDidSelect:(NSDictionary *)account {
    BOOL active = [[account valueForKey: @"active"] boolValue];
    NSMutableArray * mutableAccounts = [globalController.accounts mutableCopy];

    NSDictionary * accountToAdd;
    NSDictionary * accountToRemove;

    int i;
    for (i = 0; i < mutableAccounts.count; i++) {
        NSDictionary * acct = [mutableAccounts objectAtIndex: i];
        NSMutableDictionary * acctCopy = [acct mutableCopy];

        if ([acct isEqualToDictionary: account]) {
            [acctCopy setValue: [NSNumber numberWithBool:!active] forKey:@"active"];
            accountToAdd = [acctCopy copy];
            accountToRemove = acct;

            break;
        }
    }

    [mutableAccounts removeObject: accountToRemove];
    [mutableAccounts addObject: accountToAdd];

    [globalController updateAccounts: [mutableAccounts copy]];
}



#pragma mark - Navigation

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneBarButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
