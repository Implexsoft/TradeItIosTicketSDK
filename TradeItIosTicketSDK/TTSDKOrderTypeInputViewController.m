//
//  OrderTypeInputViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/18/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKOrderTypeInputViewController.h"
#import "TTSDKUtils.h"

@interface TTSDKOrderTypeInputViewController ()

@property (weak, nonatomic) IBOutlet UILabel *orderTypeLabel;
@property (weak, nonatomic) IBOutlet UIView *keypadContainer;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@property TTSDKUtils * utils;
@property NSString * limitPrice;
@property NSString * stopPrice;
@property NSString * currentFocus;
@property (weak, nonatomic) IBOutlet UITextField *limitPriceField;
@property (weak, nonatomic) IBOutlet UITextField *stopPriceField;
@property (weak, nonatomic) IBOutlet UIView *companyDetails;

@end

@implementation TTSDKOrderTypeInputViewController

-(void) viewWillAppear:(BOOL)animated {
    self.orderTypeLabel.text = self.orderType;

    self.limitPrice = nil;
    self.stopPrice = nil;

    if (self.tradeSession.orderInfo.price.limitPrice) {
        self.limitPrice = [self.tradeSession.orderInfo.price.limitPrice stringValue];
        self.limitPriceField.text = self.limitPrice;
    }

    if (self.tradeSession.orderInfo.price.stopPrice) {
        self.stopPrice = [self.tradeSession.orderInfo.price.stopPrice stringValue];
        self.stopPriceField.text = self.stopPrice;
    }

    if ([self.orderType isEqualToString:@"stop"]) {
        [self stopPricePressed: self];
    } else {
        [self limitPricePressed: self];
    }
}

-(void) viewDidLoad {
    [super viewDidLoad];

    self.utils = [TTSDKUtils sharedUtils];

    TTSDKCompanyDetails * companyDetailsNib = [self.utils companyDetailsWithName:@"TTSDKCompanyDetailsView" intoContainer:self.companyDetails inController:self];

    [companyDetailsNib populateDetailsWithSymbol:self.tradeSession.orderInfo.symbol andLastPrice:[NSNumber numberWithDouble:self.tradeSession.lastPrice] andChange:self.tradeSession.priceChangeDollar andChangePct:self.tradeSession.priceChangePercentage];

    [self.utils initKeypadWithName:@"TTSDKcalc" intoContainer:self.keypadContainer onPress:@selector(keypadPressed:) inController:self];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL isLimit = textField == self.limitPriceField;
    BOOL isStop = textField == self.stopPriceField;

    if (isLimit) {
        [self limitPricePressed: self];
    } else if (isStop) {
        [self stopPriceField];
    }

    return NO;
}

- (IBAction)limitPricePressed:(id)sender {
    self.currentFocus = @"limitPrice";
    [self checkIfReadyToSubmit];
}

- (IBAction)stopPricePressed:(id)sender {
    self.currentFocus = @"stopPrice";
    [self checkIfReadyToSubmit];
}

-(IBAction) keypadPressed:(id)sender {
    UIButton * button = sender;
    NSInteger key = button.tag;

    BOOL focusIsLimitPrice = [self.currentFocus isEqualToString:@"limitPrice"];
    BOOL focusIsStopPrice = [self.currentFocus isEqualToString:@"stopPrice"];

    if (focusIsLimitPrice) {
        [self limitPriceChangedByProxy:key];
    } else if (focusIsStopPrice) {
        [self stopPriceChangedByProxy:key];
    }
}

-(void) limitPriceChangedByProxy:(NSInteger) key {
    NSString * currentLimitPrice = self.limitPrice == nil ? @"" : self.limitPrice;

    if (key == 10 && [currentLimitPrice rangeOfString:@"."].location != NSNotFound) { // don't allow more than one decimal point
        return;
    }

    NSString * newLimitString;

    if (key == 11) { // backspace
        newLimitString = [currentLimitPrice substringToIndex:[currentLimitPrice length] - 1];
    } else if (key == 10) { // decimal point
        newLimitString = [NSString stringWithFormat:@"%@.", currentLimitPrice];
    } else {
        newLimitString = [NSString stringWithFormat:@"%@%li", currentLimitPrice, (long)key];
    }

    self.limitPrice = newLimitString;
    self.limitPriceField.text = newLimitString;

    [self checkIfReadyToSubmit];
}

-(void) stopPriceChangedByProxy:(NSInteger) key {
    NSString * currentStopPrice = self.stopPrice == nil ? @"" : self.stopPrice;

    if (key == 10 && [currentStopPrice rangeOfString:@"."].location != NSNotFound) { // don't allow more than one decimal point
        return;
    }
    
    NSString * newStopString;
    
    if (key == 11) { // backspace
        newStopString = [currentStopPrice substringToIndex:[currentStopPrice length] - 1];
    } else if (key == 10) { // decimal point
        newStopString = [NSString stringWithFormat:@"%@.", currentStopPrice];
    } else {
        newStopString = [NSString stringWithFormat:@"%@%li", currentStopPrice, (long)key];
    }

    self.stopPrice = newStopString;
    self.stopPriceField.text = newStopString;

    [self checkIfReadyToSubmit];
}

-(BOOL) checkIfReadyToSubmit {
    BOOL isReady = NO;

    if([self.orderType isEqualToString:@"limit"] && self.limitPrice){
        isReady = YES;
    } else if([self.orderType isEqualToString:@"stopMarket"] && self.stopPrice){
        isReady = YES;
    } else if([self.orderType isEqualToString:@"stopLimit"] && self.limitPrice && self.stopPrice){
        isReady = YES;
    }

    if (isReady) {
        [self.utils styleMainActiveButton:self.submitButton];
        self.submitButton.enabled = YES;
    } else {
        [self.utils styleMainInactiveButton:self.submitButton];
        self.submitButton.enabled = NO;
    }

    return isReady;
}

-(IBAction) submitButtonPressed:(id)sender {
    if([self.orderType isEqualToString:@"limit"]){
        self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initLimit:[self.limitPrice doubleValue]];
    } else if([self.orderType isEqualToString:@"stop"]){
        self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopMarket:[self.stopPrice doubleValue]];
    } else if([self.orderType isEqualToString:@"stopLimit"]){
        self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopLimit:[self.limitPrice doubleValue] :[self.stopPrice doubleValue]];
    }

    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
