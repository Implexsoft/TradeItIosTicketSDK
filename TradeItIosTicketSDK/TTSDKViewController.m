//
//  TTSDKViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 4/6/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKViewController.h"

@interface TTSDKViewController () {
    BOOL viewStylesCalled;
}

@end

@implementation TTSDKViewController



#pragma mark - Rotation

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}



#pragma mark - Initialization

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!viewStylesCalled) {
        [self setViewStyles];
        viewStylesCalled = YES;
    }
}

-(void) setViewStyles {
    self.styles = [TradeItStyles sharedStyles];

    self.view.backgroundColor = self.styles.pageBackgroundColor;

    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : self.styles.navigationBarTitleColor}];
    self.navigationController.navigationBar.barTintColor = self.styles.navigationBarBackgroundColor;
    self.navigationController.navigationBar.tintColor = self.styles.activeColor;
}

@end
