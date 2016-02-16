//
//  OrderTypeInputViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/18/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKOrderTypeInputViewController.h"
#import "TTSDKCompanyDetails.h"
#import "TTSDKUtils.h"
#import "TTSDKTicketController.h"

@interface TTSDKOrderTypeInputViewController () {
    TTSDKTicketController * globalController;
    TTSDKUtils * utils;
}

@property (weak, nonatomic) IBOutlet UILabel *orderTypeLabel;
@property (weak, nonatomic) IBOutlet UIView *keypadContainer;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property NSString * limitPrice;
@property NSString * stopPrice;
@property NSString * currentFocus;
@property (weak, nonatomic) IBOutlet UITextField *limitPriceField;
@property (weak, nonatomic) IBOutlet UITextField *stopPriceField;
@property (weak, nonatomic) IBOutlet UIView *companyDetails;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stopPriceTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *limitPriceTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *orderTypeTopConstraint;

@end

@implementation TTSDKOrderTypeInputViewController



#pragma mark - Orientation

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}



#pragma mark - Initialization

-(void) viewDidLoad {
    [super viewDidLoad];
    globalController = [TTSDKTicketController globalController];
    utils = [TTSDKUtils sharedUtils];

    self.orderTypeLabel.text = [utils splitCamelCase:self.orderType];

    self.limitPrice = nil;
    self.stopPrice = nil;

    if ([utils isSmallScreen]) {
        self.limitPriceTopConstraint.constant /= 2;
        self.stopPriceTopConstraint.constant /= 2;
        self.contentHeightConstraint.constant = 300;
        self.orderTypeTopConstraint.constant /= 2;
    }

    NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterCurrencyStyle;

    if (globalController.currentSession.previewRequest.orderLimitPrice) {
        self.limitPrice = [globalController.currentSession.previewRequest.orderLimitPrice stringValue];
        self.limitPriceField.text = [nf stringFromNumber: globalController.currentSession.previewRequest.orderLimitPrice];
    }

    if (globalController.currentSession.previewRequest.orderStopPrice) {
        self.stopPrice = [globalController.currentSession.previewRequest.orderStopPrice stringValue];
        self.stopPriceField.text = [nf stringFromNumber: globalController.currentSession.previewRequest.orderStopPrice];
    }

    if ([self.orderType isEqualToString:@"limit"]) {
        self.stopPriceField.hidden = YES;
        self.limitPriceField.hidden = NO;
        self.limitPriceTopConstraint.constant = self.stopPriceTopConstraint.constant;
        self.currentFocus = @"limitPrice";
    }

    if ([self.orderType isEqualToString:@"stopLimit"]) {
        self.stopPriceField.hidden = NO;
        self.limitPriceField.hidden = NO;
        self.currentFocus = @"stopPrice";
    }
    
    if ([self.orderType isEqualToString:@"stopMarket"]) {
        self.stopPriceField.hidden = NO;
        self.limitPriceField.hidden = YES;
        self.currentFocus = @"stopPrice";
    }

    TTSDKCompanyDetails * companyDetailsNib = [utils companyDetailsWithName:@"TTSDKCompanyDetailsView" intoContainer:self.companyDetails inController:self];

    [companyDetailsNib populateDetailsWithPosition:globalController.position];
    companyDetailsNib.symbolLabel.tintColor = [UIColor blackColor];

    [utils initKeypadWithName:@"TTSDKcalc" intoContainer:self.keypadContainer onPress:@selector(keypadPressed:) inController:self];

    [self checkIfReadyToSubmit];
}



#pragma mark - Delegate Methods

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL isLimit = textField == self.limitPriceField;
    BOOL isStop = textField == self.stopPriceField;

    if (isLimit) {
        [self limitPricePressed: self];
    } else if (isStop) {
        [self stopPricePressed: self];
    }

    return NO;
}



#pragma mark - Events

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



#pragma mark - Keypad Events

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



#pragma mark - State

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
        [utils styleMainActiveButton:self.submitButton];
        self.submitButton.enabled = YES;
    } else {
        [utils styleMainInactiveButton:self.submitButton];
        self.submitButton.enabled = NO;
    }

    return isReady;
}



#pragma mark - Navigation

-(IBAction) submitButtonPressed:(id)sender {
    NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;

    if([self.orderType isEqualToString:@"limit"]){
        globalController.currentSession.previewRequest.orderPriceType = @"limit";
        globalController.currentSession.previewRequest.orderLimitPrice = [nf numberFromString: self.limitPrice];
    } else if([self.orderType isEqualToString:@"stopMarket"]){
        globalController.currentSession.previewRequest.orderPriceType = @"stopMarket";
        globalController.currentSession.previewRequest.orderStopPrice = [nf numberFromString: self.stopPrice];
    } else if([self.orderType isEqualToString:@"stopLimit"]){
        globalController.currentSession.previewRequest.orderPriceType = @"stopLimit";
        globalController.currentSession.previewRequest.orderStopPrice = [nf numberFromString: self.stopPrice];
        globalController.currentSession.previewRequest.orderLimitPrice = [nf numberFromString: self.limitPrice];
    }

    [self.navigationController popToRootViewControllerAnimated:YES];
}



@end
