//
//  TTSDKPortfolioViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/16/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioViewController.h"
#import "TTSDKPortfolioTableViewCell.h"
#import "TTSDKUtils.h"

@interface TTSDKPortfolioViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *editBrokersButton;
@property (weak, nonatomic) IBOutlet UIButton *doneEditingBrokersButton;
@property TTSDKUtils * utils;

@end

@implementation TTSDKPortfolioViewController

-(void) viewDidLoad {
    [super viewDidLoad];

    self.utils = [TTSDKUtils sharedUtils];

    [self.utils styleMainActiveButton:self.doneEditingBrokersButton];

    [self updateEditStyles];
}

-(IBAction) editBrokersPressed:(id)sender {
    [self.tableView setEditing:YES animated:YES];
    [self updateEditStyles];
}

-(IBAction) doneEditingBrokersPressed:(id)sender {
    [self.tableView setEditing:NO animated:YES];
    [self updateEditStyles];
}

-(void) updateEditStyles {
    if (self.tableView.editing) {
        self.editBrokersButton.hidden = YES;
        self.doneEditingBrokersButton.hidden = NO;
    } else {
        self.editBrokersButton.hidden = NO;
        self.doneEditingBrokersButton.hidden = YES;
    }
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
    [addAccount.titleLabel setFont: [UIFont systemFontOfSize:15.0f]];
    addAccount.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [addAccount setUserInteractionEnabled:YES];

    UITapGestureRecognizer * addAccountTap = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(addAccountPressed:)];
    [addAccount addGestureRecognizer:addAccountTap];

    footerView.backgroundColor = [UIColor whiteColor];

    [footerView addSubview:addAccount];

    return footerView;
}

-(IBAction) addAccountPressed:(id)sender {
    [self performSegueWithIdentifier:@"PortfolioToBrokerSelect" sender:self];
}

-(BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
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

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PortfolioToBrokerSelect"]) {
        TTSDKBrokerSelectViewController * dest = [segue destinationViewController];
        [dest setTradeSession:self.tradeSession];
    }
}


@end