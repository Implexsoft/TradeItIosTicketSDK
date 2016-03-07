//
//  SuccessViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/26/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKSuccessViewController.h"
#import "TradeItPlaceTradeResult.h"
#import "TTSDKTradeViewController.h"
#import "TTSDKTradeItTicket.h"
#import "TTSDKUtils.h"

@interface TTSDKSuccessViewController() {
    TTSDKUtils * utils;
    TTSDKTradeItTicket * globalTicket;

    __weak IBOutlet UIButton *tradeButton;
    __weak IBOutlet UILabel *successMessage;
}

@end

@implementation TTSDKSuccessViewController



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

    globalTicket = [TTSDKTradeItTicket globalTicket];
    utils = [TTSDKUtils sharedUtils];

    TradeItPlaceTradeResult * result = globalTicket.resultContainer.tradeResponse;

    if (result.confirmationMessage) {
        [successMessage setText: result.confirmationMessage];
    }

    [utils styleMainActiveButton:tradeButton];

    NSMutableAttributedString * logoString = [[NSMutableAttributedString alloc] initWithAttributedString:[utils logoStringLight]];
    [logoString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0f] range:NSMakeRange(0, 7)];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationItem setHidesBackButton:YES];
}



#pragma mark - Navigation

- (IBAction)closeButtonPressed:(id)sender {
    [globalTicket returnToParentApp];
}

- (IBAction)tradeButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}



@end
