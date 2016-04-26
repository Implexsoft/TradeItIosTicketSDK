//
//  SuccessViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/26/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKSuccessViewController.h"
#import "TTSDKPrimaryButton.h"
#import "TradeItPlaceTradeResult.h"
#import "TTSDKTradeViewController.h"

@interface TTSDKSuccessViewController() {
    __weak IBOutlet TTSDKPrimaryButton *tradeButton;
    __weak IBOutlet UILabel *successMessage;
}

@end

@implementation TTSDKSuccessViewController


#pragma mark Initialization

- (void)viewDidLoad {
    [super viewDidLoad];

    TradeItPlaceTradeResult * result = self.ticket.resultContainer.tradeResponse;

    if (result) {
        // tell the portfolio to reload data
        self.ticket.clearPortfolioCache = YES;
    }

    if (result.confirmationMessage) {
        [successMessage setText: result.confirmationMessage];
    }

    [tradeButton activate];

    NSMutableAttributedString * logoString = [[NSMutableAttributedString alloc] initWithAttributedString:[self.utils logoStringLight]];
    [logoString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0f] range:NSMakeRange(0, 7)];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationItem setHidesBackButton:YES];
}


#pragma mark Navigation

- (IBAction)closeButtonPressed:(id)sender {
    [self.ticket returnToParentApp];
}

- (IBAction)tradeButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}


@end
