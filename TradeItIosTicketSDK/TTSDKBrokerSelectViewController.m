//
//  BrokerSelectViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/20/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBrokerSelectViewController.h"
#import "TTSDKBrokerSelectTableViewCell.h"
#import "TTSDKTradeItTicket.h"

@implementation TTSDKBrokerSelectViewController {
    NSArray * brokers;
    NSArray * linkedBrokers;
    TTSDKTradeItTicket * globalTicket;
}



#pragma mark - Constants

static NSString * kCellIdentifier = @"BrokerCell";
static NSString * kBrokerToLoginSegueIdentifier = @"BrokerSelectToLogin";



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
    [super viewDidLoad];

    [self.tableView setContentInset: UIEdgeInsetsZero];
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];

    globalTicket = [TTSDKTradeItTicket globalTicket];
    brokers = globalTicket.brokerList;

    if([brokers count] < 1){
        [self showLoadingAndWait];
    }

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 100.0f)];
    headerView.backgroundColor = [UIColor whiteColor];
    UILabel *headerLabelView = [[UILabel alloc] initWithFrame:CGRectMake(0, (headerView.frame.origin.y + headerView.frame.size.height) - 60.0f, headerView.frame.size.width, 60.0f)];
    headerLabelView.text = @"Link your broker account \n to enable trading";
    headerLabelView.numberOfLines = 0;
    headerLabelView.textAlignment = NSTextAlignmentCenter;
    headerLabelView.backgroundColor = [UIColor whiteColor];
    [headerView addSubview:headerLabelView];

    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}



#pragma mark - Table Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [brokers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * displayText = [[brokers objectAtIndex:indexPath.row] objectAtIndex:0];
    
    TTSDKBrokerSelectTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier: kCellIdentifier];
    [cell configureCellWithText:displayText];
    
    return cell;
}



#pragma mark - Custom UI

-(void) showLoadingAndWait {
    [TTSDKMBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        int cycles = 0;

        while([globalTicket.brokerList count] < 1 && cycles < 10) {
            sleep(1);
            cycles++;
        }

        if([globalTicket.brokerList count] < 1) {
            if(![UIAlertController class]) {
                [self showOldErrorAlert];
                return;
            }

            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"An Error Has Occurred"
                                                                            message:@"TradeIt is temporarily unavailable. Please try again in a few minutes."
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            alert.modalPresentationStyle = UIModalPresentationPopover;
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       [globalTicket returnToParentApp];
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
                brokers = globalTicket.brokerList;
                [self.tableView reloadData];

                [TTSDKMBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }
    });
}



#pragma mark - Navigation

- (IBAction)closePressed:(id)sender {
    if (self.isModal) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }

    if(globalTicket.brokerSignUpCallback) {
        TradeItAuthControllerResult * res = [[TradeItAuthControllerResult alloc] init];
        res.success = false;
        res.errorTitle = @"Cancelled";

        globalTicket.brokerSignUpCallback(res);
    }

    [globalTicket returnToParentApp];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:kBrokerToLoginSegueIdentifier]) {
        NSString * selectedBroker = [brokers objectAtIndex:[[self.tableView indexPathForSelectedRow] row]][1];

        TTSDKLoginViewController * dest = (TTSDKLoginViewController *)[segue destinationViewController];
        [dest setIsModal: self.isModal];
        [dest setAddBroker: selectedBroker];
    }
}

//placeholder action used in storyboard segue to unwind
- (IBAction)unwindToBrokerSelect:(UIStoryboardSegue *)unwindSegue {
    
}



#pragma mark - iOS7 fallback

-(void) showOldErrorAlert {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:@"An Error Has Occurred" message:@"TradeIt is temporarily unavailable. Please try again in a few minutes." delegate: self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [globalTicket returnToParentApp];
}



@end



























