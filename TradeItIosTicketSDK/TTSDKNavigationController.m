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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setViewStyles];
}

-(void) setViewStyles {
    self.styles = [TTSDKStyles sharedStyles];

    self.view.backgroundColor = self.styles.pageBackgroundColor;

    self.navigationController.navigationBar.backgroundColor = self.styles.navigationBarBackgroundColor;
    self.navigationController.navigationBar.tintColor = self.styles.activeColor;
}

@end
