//
//  SuccessViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/26/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKSuccessViewController.h"

@interface TTSDKSuccessViewController() {

    __weak IBOutlet UILabel *successMessage;
    __weak IBOutlet UILabel *tradeItLabel;
    
}

@end

@implementation TTSDKSuccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [successMessage setText:[NSString stringWithFormat:@"Congratulations.\r%@", [[self result] confirmationMessage]]];
    
    NSMutableAttributedString * poweredBy = [[NSMutableAttributedString alloc]initWithString:@"powered by "];
    NSMutableAttributedString * logoString = [[NSMutableAttributedString alloc] initWithAttributedString:[TTSDKTradeItTicket logoStringLite]];
    [logoString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17.0f] range:NSMakeRange(0, 7)];
    [poweredBy appendAttributedString:logoString];
    [tradeItLabel setAttributedText:poweredBy];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction)closeButtonPressed:(id)sender {
    [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
}

@end
































