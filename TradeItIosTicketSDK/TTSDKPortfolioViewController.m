//
//  TTSDKPortfolioViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/16/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioViewController.h"
#import "TTSDKPortfolioTableViewCell.h"

@interface TTSDKPortfolioViewController ()

@end

@implementation TTSDKPortfolioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"MyReuseIdentifier";
    TTSDKPortfolioTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[TTSDKPortfolioTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
    }
//    cell.textLabel.text = @"hi there";

    [cell configureCell];
    

    return cell;
}

@end
