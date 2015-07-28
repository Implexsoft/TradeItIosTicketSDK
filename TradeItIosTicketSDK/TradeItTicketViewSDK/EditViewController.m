//
//  EditViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/23/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "EditViewController.h"

@interface EditViewController () {
    
    __weak IBOutlet UIPickerView *orderTypePicker;
    __weak IBOutlet UISegmentedControl *expirationToggle;
}

@end

@implementation EditViewController

- (NSArray *) getOrderActionTitles {
    NSArray * actions = @[@"Buy",@"Sell",@"Buy to Cover",@"Sell Short"];
    return actions;
}
- (NSArray *) getOrderTypeTitles {
    NSArray * types = @[@"Market",@"Limit",@"Stop Market",@"Stop Limit"];
    return types;
}
- (NSArray *) getOrderActionValues {
    NSArray * actions = @[@"buy",@"sell",@"buyToCover",@"sellShort"];
    return actions;
}
- (NSArray *) getOrderTypeValues {
    NSArray * types = @[@"market",@"limit",@"stopMarket",@"stopLimit"];
    return types;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSArray * actions = [self getOrderActionValues];
    int i;
    for(i = (int) actions.count - 1; i > 0; i--) {
        if([actions[i] isEqualToString: [[[self tradeSession] orderInfo] action]]) {
            break;
        }
    }
    [orderTypePicker selectRow:i inComponent:0 animated:NO];
    
    NSArray * types = [self getOrderTypeValues];
    for(i = (int) types.count - 1; i > 0; i--) {
        if([types[i] isEqualToString:self.tradeSession.orderInfo.price.type]) {
            break;
        }
    }
    [orderTypePicker selectRow:i inComponent:1 animated:NO];
    
    if([[[[self tradeSession] orderInfo] expiration] isEqualToString: @"day"]) {
        expirationToggle.selectedSegmentIndex = 0;
    } else {
        expirationToggle.selectedSegmentIndex = 1;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 4;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(component == 1) {
        return [self getOrderTypeTitles][row];
    } else {
        return [self getOrderActionTitles][row];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(component == 1) {
        self.tradeSession.orderInfo.price.type = [self getOrderTypeValues][row];
    } else {
        [[[self tradeSession] orderInfo] setAction: [self getOrderActionValues][row]];
    }
}

- (IBAction)expirationToggled:(id)sender {
    UISegmentedControl * toggle = (UISegmentedControl *) sender;
    
    if(toggle.selectedSegmentIndex == 0) {
        [[[self tradeSession] orderInfo] setExpiration: @"day"];
    } else {
        [[[self tradeSession] orderInfo] setExpiration: @"gtc"];
    }
}

@end

























