//
//  LoginViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/23/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController () {
    
    __weak IBOutlet UILabel *logoLabel;
    __weak IBOutlet UITextView *logoSubText;
    __weak IBOutlet UITextField *emailInput;
    __weak IBOutlet UITextField *passwordInput;
    __weak IBOutlet UIButton *nextButton;
    
    NSArray * brokers;
}

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [logoLabel setAttributedText:[TradeItTicket logoString]];
    emailInput.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    passwordInput.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    
    emailInput.layer.borderWidth = 1;
    passwordInput.layer.borderWidth = 1;
    
    [logoSubText setText:[NSString stringWithFormat:@"Welcome to Trade It. We help you quickly and easily trade stock through your own brokerage account. Select your broker below and buy %@ stock within seconds.", self.tradeSession.orderInfo.symbol]];
    
    [nextButton.layer setCornerRadius:5.0f];
    
    brokers = @[
        @[@"TD Ameritrade",@"TD"],
        @[@"Robinghood",@"Robinhood"],
        @[@"OptionsHouse",@"OptionsHouse"],
        @[@"Schwab",@"Schwabs"],
        @[@"TradeStation",@"TradeStation"],
        @[@"E*Trade",@"Etrade"],
        @[@"Fidelity",@"Fidelity"],
        @[@"Scottrade",@"Scottrade"],
        @[@"Interactive Brokers",@"IB"]
    ];
    
    if([[self tradeSession] debugMode]) {
        NSArray * dummy  =  @[@[@"Dummy",@"Dummy"]];
        brokers = [dummy arrayByAddingObjectsFromArray: brokers];
    }
    
    self.tradeSession.broker = brokers[0][1];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if([[self tradeSession] popToRoot]) {
        [[self tradeSession] setPopToRoot:NO];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma Broker Picker View

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [brokers count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return brokers[row][0];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.tradeSession.broker = brokers[row][1];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    self.tradeSession.authenticationInfo = [[TradeItAuthenticationInfo alloc]initWithId:emailInput.text andPassword:passwordInput.text];
    
    [[segue destinationViewController] setActionToPerform: @"sendLoginReviewRequest"];
    [[segue destinationViewController] setTradeSession: self.tradeSession];
}

@end
