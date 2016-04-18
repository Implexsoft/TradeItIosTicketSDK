//
//  TTSDKNavigationController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 4/12/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKNavigationController.h"

@interface TTSDKNavigationController ()

@end

@implementation TTSDKNavigationController



#pragma mark - Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

- (BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}



#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setViewStyles];
}

-(void) setViewStyles {
    self.styles = [TradeItStyles sharedStyles];

    self.view.backgroundColor = self.styles.pageBackgroundColor;
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : self.styles.navigationBarTitleColor}];
    self.navigationController.navigationBar.barTintColor = self.styles.navigationBarBackgroundColor;
    self.navigationController.navigationBar.tintColor = self.styles.activeColor;
}

@end
