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

-(void) viewDidLoad {
    [super viewDidLoad];


}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView * footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];

    UIButton * addAccount = [[UIButton alloc] initWithFrame:CGRectMake(footerView.frame.origin.x + 43, footerView.frame.origin.y, footerView.frame.size.width / 2, footerView.frame.size.height / 2)];
    [addAccount setTitle:@"Add Account" forState:UIControlStateNormal];
    addAccount.tintColor = [UIColor colorWithRed:0.00f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
    [addAccount setTitleColor:[UIColor colorWithRed:0.00f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    [addAccount.titleLabel setFont: [UIFont systemFontOfSize:12.0f]];
    addAccount.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    [footerView addSubview:addAccount];

    return footerView;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * portfolioIdentifier = @"PortfolioIdentifier";
    TTSDKPortfolioTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:portfolioIdentifier];
    if (cell == nil) {
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
        NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];

        [tableView registerNib:[UINib nibWithNibName:@"TTSDKPortfolioCell" bundle:resourceBundle] forCellReuseIdentifier:portfolioIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:portfolioIdentifier];
    }

    [cell configureCell];

    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}

@end