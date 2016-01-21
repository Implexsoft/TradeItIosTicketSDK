//
//  TTSDKSymbolSearchViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/17/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKSymbolSearchViewController.h"

@interface TTSDKSymbolSearchViewController ()

@end

@implementation TTSDKSymbolSearchViewController

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}

@end
