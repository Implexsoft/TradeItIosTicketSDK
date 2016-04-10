//
//  TTSDKBaseViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/12/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKTabBarViewController.h"
#import "TTSDKStyles.h"

@implementation TTSDKTabBarViewController

#pragma mark - Rotation

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}



#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];

    TTSDKStyles * styles = [TTSDKStyles sharedStyles];

    self.navigationController.navigationBar.backgroundColor = styles.navigationBarBackgroundColor;
    self.navigationController.navigationBar.tintColor = styles.activeColor;

    [[UITabBar appearanceWhenContainedIn:self.class, nil] setTintColor: styles.tabBarItemColor];
    [[UITabBar appearanceWhenContainedIn:self.class, nil] setBarTintColor: styles.tabBarBackgroundColor];
}



@end
