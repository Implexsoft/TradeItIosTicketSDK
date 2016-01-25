//
//  TTSDKPortfolioViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/16/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountSelectViewController.h"
#import "TTSDKAccountSelectTableViewCell.h"
#import "TTSDKUtils.h"

@interface TTSDKAccountSelectViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *editBrokersButton;
@property TTSDKUtils * utils;

@end

@implementation TTSDKAccountSelectViewController

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}

-(void) viewDidLoad {
    [super viewDidLoad];



    self.utils = [TTSDKUtils sharedUtils];
}

-(IBAction) editBrokersPressed:(id)sender {
    [self performSegueWithIdentifier:@"AccountSelectToAccountLink" sender:self];
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    // create a blank footer to remove extra separators
    UIView * footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0)];
    return footerView;
}

-(void) addFooter {
    UIView * footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
    
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
    
    self.tableView.tableFooterView = footerView;
}

-(IBAction) addAccountPressed:(id)sender {
    [self performSegueWithIdentifier:@"AccountSelectToBrokerSelect" sender:self];
}

-(BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * accountIdentifier = @"AccountSelect";
    TTSDKAccountSelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:accountIdentifier];
    if (cell == nil) {
        NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
        NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];

        [tableView registerNib:[UINib nibWithNibName:@"TTSDKAccountSelectCell" bundle:resourceBundle] forCellReuseIdentifier:accountIdentifier];
        cell = [tableView dequeueReusableCellWithIdentifier:accountIdentifier];
    }

    [cell configureCell];

    return cell;
}



@end