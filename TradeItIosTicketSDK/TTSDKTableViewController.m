//
//  TTSDKTableViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 4/8/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKTableViewController.h"

@implementation TTSDKTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setViewStyles];
}

-(void) setViewStyles {
    self.styles = [TTSDKStyles sharedStyles];

    self.view.backgroundColor = self.styles.pageBackgroundColor;

    [[UIButton appearanceWhenContainedIn: self.class, nil] setBackgroundColor: [UIColor clearColor]];
    [[UIBarButtonItem appearanceWhenContainedIn: self.class, nil] setTintColor:[UIColor greenColor]];

    self.navigationController.navigationBar.backgroundColor = self.styles.navigationBarBackgroundColor;
    self.navigationController.navigationBar.tintColor = self.styles.activeColor;

    self.tableView.separatorColor = self.styles.primarySeparatorColor;
}

@end
