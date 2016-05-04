//
//  TTSDKTableViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 4/8/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKTableViewController.h"

@implementation TTSDKTableViewController


#pragma mark Rotation

-(BOOL) shouldAutorotate {
    return NO;
}

-(UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

-(UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark Initialization

-(void) viewDidLoad {
    [super viewDidLoad];

    self.ticket = [TTSDKTradeItTicket globalTicket];
    self.utils = [TTSDKUtils sharedUtils];
    self.styles = [TradeItStyles sharedStyles];

    [self setViewStyles];
}

-(void) setViewStyles {
    self.view.backgroundColor = self.styles.pageBackgroundColor;

    self.navigationController.navigationBar.barTintColor = self.styles.navigationBarBackgroundColor;
    self.navigationController.navigationBar.tintColor = self.styles.activeColor;

    self.tableView.separatorColor = self.styles.primarySeparatorColor;
}


#pragma mark iOS7 fallbacks

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

#pragma mark Navigation

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.ticket.lastUsed = [NSDate date];
}


@end
