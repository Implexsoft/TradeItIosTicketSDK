//
//  SuccessViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/26/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKSuccessViewController.h"
#import "TTSDKUtils.h"

@interface TTSDKSuccessViewController() {
    TTSDKUtils * utils;
    __weak IBOutlet UIButton *tradeButton;
    __weak IBOutlet UILabel *successMessage;
}

@end

@implementation TTSDKSuccessViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    self.tradeSession = [TTSDKTicketSession globalSession];
    utils = [TTSDKUtils sharedUtils];
    
    [successMessage setText:[NSString stringWithFormat:@"%@", [[self result] confirmationMessage]]];

    [utils styleMainActiveButton:tradeButton];

    NSMutableAttributedString * logoString = [[NSMutableAttributedString alloc] initWithAttributedString:[utils logoStringLight]];
    [logoString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0f] range:NSMakeRange(0, 7)];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationItem setHidesBackButton:YES];
}



#pragma mark - Navigation

- (IBAction)closeButtonPressed:(id)sender {
    [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
}

- (IBAction)tradeButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}


@end
