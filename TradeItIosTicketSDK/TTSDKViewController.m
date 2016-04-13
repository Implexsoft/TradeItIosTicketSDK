//
//  TTSDKViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 4/6/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKViewController.h"

@interface TTSDKViewController ()

@end

@implementation TTSDKViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setViewStyles];
}

-(void) setViewStyles {
    self.styles = [TTSDKStyles sharedStyles];

    self.view.backgroundColor = self.styles.pageBackgroundColor;

    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : self.styles.navigationBarTitleColor}];

    self.navigationController.navigationBar.backgroundColor = self.styles.navigationBarBackgroundColor;
    self.navigationController.navigationBar.tintColor = self.styles.activeColor;
}

@end
