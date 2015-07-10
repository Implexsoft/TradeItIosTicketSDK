//
//  SuccessViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/26/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "SuccessViewController.h"

@interface SuccessViewController() {

}

@end

@implementation SuccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*
    [successMessage setText:[NSString stringWithFormat:@"Congratulations.\rYour order message %@ to buy %@ shares of %@ at %@ has been successfully transmitted to your broker at %@", @"2d466185c40726050eb0cd", @"5", @"GE", @"market price", @"26/06/15 4:54 PM EDT."]];

    NSMutableAttributedString * poweredBy = [[NSMutableAttributedString alloc]initWithString:@"powered by "];
    [poweredBy appendAttributedString:[TradeItTicket logoStringLite]];
    [tradeItLabel setAttributedText:poweredBy];
     */
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
    
    //[self.navigationController popToRootViewControllerAnimated:NO];
}

@end
