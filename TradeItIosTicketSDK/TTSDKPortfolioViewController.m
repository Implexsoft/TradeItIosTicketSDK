//
//  TTSDKPortfolioViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/5/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioViewController.h"
#import "TTSDKUtils.h"

@interface TTSDKPortfolioViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *editBrokersButton;
@property (weak, nonatomic) IBOutlet UIButton *doneEditingBrokersButton;
@property TTSDKUtils * utils;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property NSArray * testAccounts;
@property NSArray * testHoldings;

@end

@implementation TTSDKPortfolioViewController

- (IBAction)closePressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) viewDidLoad {

    self.scrollView.scrollEnabled = YES;
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, [self.scrollView.subviews firstObject].frame.size.height);
    [self.scrollView needsUpdateConstraints];

    self.testAccounts = [NSArray arrayWithObjects:
                         [NSDictionary dictionaryWithObjectsAndKeys:@"Fidelity", @"acct", @"+18,940 (6.24%)", @"value", @"$40,416", @"buyingPower", nil],
                         @"Fidelity",
                         @"Etrade",
                         @"Robinhood",
                         nil];

    self.testHoldings = [NSArray arrayWithObjects:
                         @"AAPL",
                         @"GE",
                         @"BET",
                         nil];

}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    tableView.alwaysBounceVertical = NO;
    tableView.scrollEnabled = NO;
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isHoldingsTable:tableView]) {
        return self.testAccounts.count;
    } else {
        return self.testHoldings.count;
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isHoldingsTable:tableView]) {
        return 60.0f;
    } else {
        return 43.0f;
    }
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * cellIdentifier;
    NSString * nibIdentifier;

    if ([self isHoldingsTable:tableView]) {
        cellIdentifier = @"PortfolioHoldingIdentifier";
        nibIdentifier = @"TTSDKPortfolioHoldingCell";
    } else {
        cellIdentifier = @"PortfolioAccountIdentifier";
        nibIdentifier = @"TTSDKPortfolioAccountCell";
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
        NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];

        [tableView registerNib:[UINib nibWithNibName:nibIdentifier bundle:resourceBundle] forCellReuseIdentifier:cellIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    }

    return cell;
}

-(BOOL) isHoldingsTable:(UITableView *)tableView {
    // the accounts table tag is 0 and the holdings table tag is 1
    return tableView.tag == 1;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}

@end
