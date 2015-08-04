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
    
    brokers = [TradeItTicket getAvailableBrokers:self.tradeSession];
    linkedBrokers = [TradeItTicket getLinkedBrokersList];
    
    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, -8, 0, 0);
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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



























