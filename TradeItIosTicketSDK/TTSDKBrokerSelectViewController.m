//
//  BrokerSelectViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/20/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBrokerSelectViewController.h"
#import "TTSDKBrokerSelectTableViewCell.h"

@implementation TTSDKBrokerSelectViewController {
    NSArray * brokers;
    NSArray * linkedBrokers;
}

static NSString * CellIdentifier = @"BrokerCell";

-(void) viewDidLoad {
    [super viewDidLoad];

    self.tableView.contentInset = UIEdgeInsetsZero;
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];

    brokers = self.tradeSession.brokerList;
    linkedBrokers = [TTSDKTradeItTicket getLinkedBrokersList];
    
    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
    self.navigationItem.leftBarButtonItem = cancelButton;

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

//    [headerView addConstraint:[NSLayoutConstraint constraintWithItem:headerLabelView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f]];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height - 200, self.tableView.frame.size.width, 100)];
    UIButton *footerButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 20)];
    [footerButton setTitle:@"Next" forState:UIControlStateNormal];
    [footerView addSubview:footerButton];

    [self.view addSubview:footerView];
    
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:footerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f]];

//    self.view.backgroundColor = [UIColor redColor];
//    self.tableView.backgroundColor = [UIColor yellowColor];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void) showLoadingAndWait {
    
    [TTSDKMBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        int cycles = 0;
        
        while([self.tradeSession.brokerList count] < 1 && cycles < 10) {
            sleep(1);
            cycles++;
        }
        
        if([self.tradeSession.brokerList count] < 1) {
            if(![UIAlertController class]) {
                [self showOldErrorAlert];
                return;
            }
            
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"An Error Has Occurred"
                                                                            message:@"TradeIt is temporarily unavailable. Please try again in a few minutes."
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
                                                                   }];
            [alert addAction:defaultAction];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [TTSDKMBProgressHUD hideHUDForView:self.view animated:YES];
                [self presentViewController:alert animated:YES completion:nil];
            });
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                brokers = self.tradeSession.brokerList;
                [self.tableView reloadData];
                
                [TTSDKMBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }
    });
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
    [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [brokers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * displayText = [[brokers objectAtIndex:indexPath.row] objectAtIndex:0];
    NSString * valueText = [[brokers objectAtIndex:indexPath.row] objectAtIndex:1];
    
    TTSDKBrokerSelectTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.textLabel.text = displayText;

    [cell configureCell];

    if([linkedBrokers containsObject:valueText]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    return cell;
}



#pragma mark - events

- (void)cancelButtonTapped:(id)sender {
    if([self editMode]) {
        [self performSegueWithIdentifier:@"brokerSelectToEdit" sender:self];
    } else {
        if(self.tradeSession.brokerSignUpCallback) {
            TradeItAuthControllerResult * res = [[TradeItAuthControllerResult alloc] init];
            res.success = false;
            res.errorTitle = @"Cancelled";
            
            self.tradeSession.brokerSignUpCallback(res);
        }
        
        [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"brokerDetailSegue"]) {
        [[segue destinationViewController] setAddBroker: [brokers objectAtIndex:[[self.tableView indexPathForSelectedRow] row]][1]];
        [[segue destinationViewController] setTradeSession: self.tradeSession];
    }
}

//placeholder action used in storyboard segue to unwind
- (IBAction)unwindToBrokerSelect:(UIStoryboardSegue *)unwindSegue {
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end



























