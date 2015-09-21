//
//  BrokerSelectViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/20/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "BrokerSelectViewController.h"

@implementation BrokerSelectViewController {
    NSArray * brokers;
    NSArray * linkedBrokers;
}

static NSString * CellIdentifier = @"BrokerCell";

-(void) viewDidLoad {
    [super viewDidLoad];
    
    brokers = self.tradeSession.brokerList;
    linkedBrokers = [TradeItTicket getLinkedBrokersList];
    
    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, -8, 0, 0);
    
    if([brokers count] < 1){
        [self showLoadingAndWait];
    }
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
                                                                       [TradeItTicket returnToParentApp:self.tradeSession];
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
    [TradeItTicket returnToParentApp:self.tradeSession];
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
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.textLabel.text = displayText;
    
    //Maybe someday we can add these back
    //UIImage * logo = [UIImage imageNamed: [NSString stringWithFormat: @"TradeItIosTicketSDK.bundle/%@.png", valueText]];
    //UIImage * myIcon = [TradeItTicket imageWithImage:logo scaledToWidth: 50.0f withInset: 15.0f];
    //cell.imageView.image = myIcon;
    
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
        //[[[self tradeSession] parentView] dismissViewControllerAnimated:YES completion:[[self tradeSession] callback]];
        [TradeItTicket returnToParentApp:self.tradeSession];
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



























