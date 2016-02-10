//
//  OrderTypeSelectionViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/18/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKOrderTypeSelectionViewController.h"
#import "TTSDKOrderTypeInputViewController.h"
#import "TTSDKTicketController.h"

@interface TTSDKOrderTypeSelectionViewController () {
    TTSDKTicketController * globalController;
}

@property NSString * orderType;

@end

@implementation TTSDKOrderTypeSelectionViewController



#pragma mark - Orientation

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

    globalController = [TTSDKTicketController globalController];
}



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"OrderTypeSelectionToInput"]) {
        TTSDKOrderTypeInputViewController * dest = [segue destinationViewController];
        dest.orderType = self.orderType;
    }
}

- (IBAction)marketPressed:(id)sender {
    [globalController.tradeRequest setOrderPriceType: @"market"];
    [globalController.tradeRequest setOrderLimitPrice: nil];
    [globalController.tradeRequest setOrderStopPrice: nil];

    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)limitPressed:(id)sender {
    self.orderType = @"limit";
    [self performSegueWithIdentifier:@"OrderTypeSelectionToInput" sender:self];
}

- (IBAction)stopPressed:(id)sender {
    self.orderType = @"stopMarket";
    [self performSegueWithIdentifier:@"OrderTypeSelectionToInput" sender:self];
}

- (IBAction)stopLimitPressed:(id)sender {
    self.orderType = @"stopLimit";
    [self performSegueWithIdentifier:@"OrderTypeSelectionToInput" sender:self];
}



@end
