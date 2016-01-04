//
//  LinkPromptViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/4/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKLinkPromptViewController.h"
#import "TTSDKBrokerSelectViewController.h"

@interface TTSDKLinkPromptViewController ()

@end

@implementation TTSDKLinkPromptViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)brokerSelectPressed:(id)sender {
    [self performSegueWithIdentifier:@"LinkPromptToBrokerSelect" sender:self];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"LinkPromptToBrokerSelect"]) {
        TTSDKBrokerSelectViewController * dest = [segue destinationViewController];
        [dest setTradeSession:self.tradeSession];
    }
}


@end
