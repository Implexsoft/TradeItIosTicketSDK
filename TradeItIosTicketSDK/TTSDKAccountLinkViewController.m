//
//  TTSDKAccountLinkViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/13/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountLinkViewController.h"
#import "TTSDKUtils.h"

@interface TTSDKAccountLinkViewController ()

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property TTSDKUtils * sharedUtils;

@property NSArray * testingData;

@end

@implementation TTSDKAccountLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.sharedUtils = [TTSDKUtils sharedUtils];

    [self.sharedUtils styleMainActiveButton:self.doneButton];

    self.testingData = @[
                         [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Fidelity",@"accountName",
                          @"Brokerage",@"accountType",
                          @"$12,340",@"buyingPower",
                          @"1",@"linked",
                          nil],
                         [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Robinhood",@"accountName",
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
    return self.testingData.count;
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


    [cell configureCellWithData:[self.testingData objectAtIndex:indexPath.row]];

    return cell;
}

-(void)linkToggleDidSelect {
    // if an account is toggled
}

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}


@end
