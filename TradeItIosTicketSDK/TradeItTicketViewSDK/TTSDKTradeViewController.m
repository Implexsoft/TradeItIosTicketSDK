//
//  TTSDKTradeViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/29/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKTradeViewController.h"
#import "TTSDKPrimaryButton.h"
#import "TTSDKReviewScreenViewController.h"
#import "TTSDKCompanyDetails.h"
#import "TTSDKLoginViewController.h"
#import "TradeItBalanceService.h"
#import "TTSDKPosition.h"
#import "TradeItQuotesResult.h"
#import "TTSDKImageView.h"
#import "TTSDKKeypad.h"


@interface TTSDKTradeViewController () {
    __weak IBOutlet UIView * companyDetails;
    __weak IBOutlet UIView * keypadContainer;
    __weak IBOutlet UIView * orderView;
    __weak IBOutlet UIView *containerView;
    __weak IBOutlet UITextField * sharesInput;
    __weak IBOutlet UITextField *stopPriceInput;
    __weak IBOutlet UITextField *limitPriceInput;
    __weak IBOutlet UILabel * estimatedCostLabel;
    __weak IBOutlet NSLayoutConstraint *keypadTopConstraint;
    __weak IBOutlet NSLayoutConstraint *limitPricesWidthConstraint;
    __weak IBOutlet UIButton * orderActionButton;
    __weak IBOutlet UIButton * orderTypeButton;
    __weak IBOutlet UIButton * orderExpirationButton;
    __weak IBOutlet TTSDKPrimaryButton * previewOrderButton;
    __weak IBOutlet TTSDKImageView *expirationDropdownArrow;

    TTSDKKeypad * keypad;
    UIView * loadingView;

    TTSDKCompanyDetails * companyNib;

    NSLayoutConstraint * zeroHeightConstraint;
    NSLayoutConstraint * fullHeightConstraint;

    BOOL readyToTrade;
    BOOL uiConfigured;

    NSString * currentFocus;
}

@end

@implementation TTSDKTradeViewController


#pragma mark Initialization

-(void) viewDidLoad {
    [super viewDidLoad];

    if([self.ticket.previewRequest.orderQuantity intValue] > 0) {
        [sharesInput setText:[NSString stringWithFormat:@"%i", [self.ticket.previewRequest.orderQuantity intValue]]];
    }

    [self initKeypad];
    keypadContainer.backgroundColor = self.styles.pageBackgroundColor;

    UIView * emptyKeypadFrame = [[UIView alloc] initWithFrame:CGRectZero]; // we need to set the input view of the text field so that the cursor shows up
    sharesInput.inputView = emptyKeypadFrame;
    limitPriceInput.inputView = emptyKeypadFrame;
    stopPriceInput.inputView = emptyKeypadFrame;
    [sharesInput becomeFirstResponder];

    companyNib = [self.utils companyDetailsWithName:@"TTSDKCompanyDetailsView" intoContainer:companyDetails inController:self];
    companyNib.backgroundColor = self.styles.pageBackgroundColor;

    [self setCustomEvents];
    [self refreshPressed:self];

    UITapGestureRecognizer * sharesTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sharesPressed:)];
    [sharesInput addGestureRecognizer: sharesTap];

    UITapGestureRecognizer * limitTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(limitPressed:)];
    [limitPriceInput addGestureRecognizer: limitTap];

    UITapGestureRecognizer * stopTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(stopPressed:)];
    [stopPriceInput addGestureRecognizer: stopTap];

    currentFocus = @"shares";
    [keypad hideDecimal];

    if ([self.utils isSmallScreen] && !uiConfigured) {
        [self configureUIForSmallScreens];
    }

    [self.view setNeedsDisplay];
}

-(IBAction) sharesPressed:(id)sender {
    [self styleBorderedFocusInput: sharesInput];
    [self styleBorderedUnfocusInput: limitPriceInput];
    [self styleBorderedUnfocusInput: stopPriceInput];
    [sharesInput becomeFirstResponder];
}

-(IBAction) limitPressed:(id)sender {
    [self styleBorderedUnfocusInput: sharesInput];
    [self styleBorderedFocusInput: limitPriceInput];
    [self styleBorderedUnfocusInput: stopPriceInput];
    [limitPriceInput becomeFirstResponder];
}

-(IBAction) stopPressed:(id)sender {
    [self styleBorderedUnfocusInput: sharesInput];
    [self styleBorderedUnfocusInput: limitPriceInput];
    [self styleBorderedFocusInput: stopPriceInput];
    [stopPriceInput becomeFirstResponder];
}

-(void) setViewStyles {
    [super setViewStyles];

    [self applyBorder: (UIView *)sharesInput];
    [self applyBorder: (UIView *)limitPriceInput];
    [self applyBorder: (UIView *)stopPriceInput];

    [self styleBorderedFocusInput: sharesInput];
    [self styleBorderedUnfocusInput: limitPriceInput];
    [self styleBorderedUnfocusInput: stopPriceInput];
    
    [self styleDropdownButton: orderActionButton];
    [self deactivateDropdownButton: orderActionButton];
    
    [self styleDropdownButton: orderTypeButton];
    [self deactivateDropdownButton: orderTypeButton];
    
    [self styleDropdownButton: orderExpirationButton];
    [self deactivateDropdownButton: orderExpirationButton];

    previewOrderButton.clipsToBounds = YES;
}

-(void) styleDropdownButton:(UIButton *)button {
    button.layer.borderWidth = 1;
    button.layer.cornerRadius = 3;
}

-(void) styleBorderedFocusInput: (UIView *)input {
    input.layer.borderColor = self.styles.activeColor.CGColor;
}

-(void) styleBorderedUnfocusInput: (UIView *)input {
    input.layer.borderColor = self.styles.inactiveColor.CGColor;
}

-(void) activateDropdownButton:(UIButton *)button {
    button.layer.borderColor = self.styles.activeColor.CGColor;
    [button setTitleColor:self.styles.activeColor forState:UIControlStateNormal];
}

-(void) deactivateDropdownButton:(UIButton *)button {
    button.layer.borderColor = self.styles.inactiveColor.CGColor;
    [button setTitleColor:self.styles.primaryTextColor forState:UIControlStateNormal];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!self.ticket.currentSession.isAuthenticated) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;

        [self.ticket.currentSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * res) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
            if ([res isKindOfClass:TradeItAuthenticationResult.class]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self retrieveQuoteData];
                    [self retrieveAccountSummaryData];
                    [self checkIfReadyToTrade];
                });
            } else if ([res isKindOfClass:TradeItErrorResult.class]) {
                TradeItErrorResult * error = (TradeItErrorResult *)res;
                NSMutableString * errorMessage = [[NSMutableString alloc] init];

                for (NSString * str in error.longMessages) {
                    [errorMessage appendString:str];
                }

                if(![UIAlertController class]) {
                    [self showOldErrorAlert:error.shortMessage withMessage:errorMessage];
                } else {
                    UIAlertController * alert = [UIAlertController alertControllerWithTitle:error.shortMessage
                                                                                    message:errorMessage
                                                                             preferredStyle:UIAlertControllerStyleAlert];

                    alert.modalPresentationStyle = UIModalPresentationPopover;
                    
                    UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"Login" style:UIAlertActionStyleDefault
                                                                           handler:^(UIAlertAction * action) {
                                                                               [self performSegueWithIdentifier:@"TradeToLogin" sender:self];
                                                                           }];

                    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        // do nothing
                    }];

                    [alert addAction:defaultAction];
                    [alert addAction:cancelAction];

                    [self presentViewController:alert animated:YES completion:nil];
                    
                    UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
                    alertPresentationController.sourceView = self.view;
                    alertPresentationController.permittedArrowDirections = 0;
                    alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
                }

            }
        }];
    } else {
        [self retrieveQuoteData];
        [self retrieveAccountSummaryData];
        [self checkIfReadyToTrade];
    }

    if (self.ticket.currentSession.isAuthenticated) {
        [self retrieveQuoteData];
    }

    [self populateSymbolDetails];

    [self changeOrderAction:self.ticket.previewRequest.orderAction];
    [self changeOrderType:self.ticket.previewRequest.orderPriceType];
    [self changeOrderExpiration:self.ticket.previewRequest.orderExpiration];

    [companyNib populateBrokerButtonTitle: self.ticket.currentSession.broker];
}

-(void) populateSymbolDetails {
    [companyNib populateDetailsWithQuote:self.ticket.quote];
    [companyNib populateBrokerButtonTitle: self.ticket.currentSession.broker];

    if ([self.ticket.previewRequest.orderAction isEqualToString: @"buy"]) {
        [companyNib populateSymbolDetail:self.currentPortfolioAccount.balance.buyingPower andSharesOwned:nil];
    } else {

        NSNumber * sharesOwned = @0;

        for (TTSDKPosition * position in self.currentPortfolioAccount.positions) {
            if ([position.symbol isEqualToString:self.ticket.quote.symbol]) {
                sharesOwned = position.quantity;
            }
        }

        [companyNib populateSymbolDetail:nil andSharesOwned: sharesOwned];
    }

    [self checkIfReadyToTrade];
}

-(void) initKeypad {
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
    NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];
    NSArray * keypadArray = [resourceBundle loadNibNamed:@"TTSDKcalc" owner:self options:nil];

    keypad = [keypadArray firstObject];
    [keypadContainer addSubview: keypad];
    keypad.container = keypadContainer;

    NSArray * subviews = keypad.subviews;
    for (int i = 0; i < [subviews count]; i++) {
        if (![NSStringFromClass([[subviews objectAtIndex:i] class]) isEqualToString:@"TTSDKImageView"]) {
            UIButton *button = [subviews objectAtIndex:i];
            [button addTarget:self action:@selector(keypadPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}


#pragma mark Delegate Methods

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    [keypad show];

    if (textField == sharesInput) {
        [self styleBorderedFocusInput: sharesInput];
        [self styleBorderedUnfocusInput: limitPriceInput];
        [self styleBorderedUnfocusInput: stopPriceInput];
        currentFocus = @"shares";
        [keypad hideDecimal];
    }

    if (textField == limitPriceInput) {
        [self styleBorderedUnfocusInput: sharesInput];
        [self styleBorderedFocusInput: limitPriceInput];
        [self styleBorderedUnfocusInput: stopPriceInput];
        currentFocus = @"limit";
        [keypad showDecimal];
    }

    if (textField == stopPriceInput) {
        [self styleBorderedUnfocusInput: sharesInput];
        [self styleBorderedUnfocusInput: limitPriceInput];
        [self styleBorderedFocusInput: stopPriceInput];
        currentFocus = @"stop";
        [keypad showDecimal];
    }

    return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    if ([self.utils isSmallScreen]) {
        return YES;
    } else {
        return NO;
    }
}

-(BOOL) textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}


#pragma mark Custom UI

-(void) applyBorder: (UIView *) item {
    item.layer.borderColor = self.styles.inactiveColor.CGColor;
    item.layer.borderWidth = 1;
    item.layer.cornerRadius = 3;
}

-(void) setCustomEvents {
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(brokerLinkPressed:)];
    tap.numberOfTapsRequired = 1;
    [companyNib.brokerButton addGestureRecognizer:tap];

    UITapGestureRecognizer * detailsTap = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(refreshPressed:)];
    [companyNib addGestureRecognizer:detailsTap];
    
    UITapGestureRecognizer * symbolTap = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(symbolPressed:)];
    symbolTap.numberOfTapsRequired = 1;
    [companyNib.symbolLabel addGestureRecognizer:symbolTap];
    companyNib.symbolLabel.userInteractionEnabled = YES;
}

-(void) configureUIForSmallScreens {
    uiConfigured = YES;

    if (keypadTopConstraint) {
        [containerView removeConstraint:keypadTopConstraint];
        NSLayoutConstraint * heightConstraint = [NSLayoutConstraint constraintWithItem:keypadContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:200];
        [containerView addConstraint:heightConstraint];
    }

    CALayer * borderLayer = [CALayer layer];
    borderLayer.frame = CGRectMake(0, 0, keypadContainer.frame.size.width, 1.0f);
    borderLayer.backgroundColor = self.styles.activeColor.CGColor;
    [keypadContainer.layer addSublayer:borderLayer];

    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:keypadContainer.bounds];
    keypadContainer.layer.masksToBounds = NO;
    keypadContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    keypadContainer.layer.shadowOffset = CGSizeMake(0.0f, -0.5f);
    keypadContainer.layer.shadowOpacity = 0.5f;
    keypadContainer.layer.shadowPath = shadowPath.CGPath;
    keypadContainer.layer.zPosition = 100;
}

-(void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [keypad hide];
}


#pragma mark Order

-(void) checkIfReadyToTrade {
    [self updateEstimatedCost];

    BOOL readyNow = NO;

    NSInteger shares = [sharesInput.text integerValue];

    double limitPrice = [self.ticket.previewRequest.orderLimitPrice doubleValue];
    double stopPrice = [self.ticket.previewRequest.orderStopPrice doubleValue];

    if(shares < 1) {
        readyNow = NO;
    } else if([self.ticket.previewRequest.orderPriceType isEqualToString:@"stopLimit"]) {
        if(limitPrice > 0 && stopPrice > 0) {
            readyNow = YES;
        }
    } else if([self.ticket.previewRequest.orderPriceType isEqualToString:@"market"]) {
        readyNow = YES;
    } else if([self.ticket.previewRequest.orderPriceType isEqualToString:@"stopMarket"]) {
        if(stopPrice > 0) {
            readyNow = YES;
        }
    } else {
        if(limitPrice > 0) {
            readyNow = YES;
        }
    }

    if (!self.ticket.currentSession.isAuthenticated || !self.ticket.currentAccount) {
        readyNow = NO;
    }
    
    if (!self.ticket.previewRequest.orderSymbol || [self.ticket.previewRequest.orderSymbol isEqualToString:@""]) {
        readyNow = NO;
    }

    if(readyNow) {
        [previewOrderButton activate];
    } else {
        [previewOrderButton deactivate];
    }

    readyToTrade = readyNow;
}

-(void) updateEstimatedCost {
    NSInteger shares = [self.ticket.previewRequest.orderQuantity integerValue];

    double price = [self.ticket.quote.lastPrice doubleValue];

    if([self.ticket.previewRequest.orderPriceType isEqualToString:@"stopMarket"]){
        price = [self.ticket.previewRequest.orderStopPrice doubleValue];
    } else if([self.ticket.previewRequest.orderPriceType containsString:@"imit"]) {
        price = [self.ticket.previewRequest.orderLimitPrice doubleValue];
    }

    double estimatedCost = shares * price;
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: US];

    NSString * formattedNumber = [formatter stringFromNumber: [NSNumber numberWithDouble:estimatedCost]];
    NSString * equalitySign = [self.ticket.previewRequest.orderPriceType containsString:@"arket"] ? @"\u2248" : @"=";
    NSString * actionPostfix = ([self.ticket.previewRequest.orderAction isEqualToString:@"buy"]) ? @"Cost" : @"Proceeds";
    NSString * formattedString = [NSString stringWithFormat:@"Est. %@ %@ %@", actionPostfix, equalitySign, formattedNumber];

    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:formattedString];

    [estimatedCostLabel setAttributedText:attString];
}

-(void) changeOrderQuantity:(NSInteger)key {
    if (key == 10) { // decimal key - not allowed for quantity
        return;
    }

    NSString * currentQuantityString;
    NSString * newQuantityString;
    NSString * appendedString;

    if (!self.ticket.previewRequest.orderQuantity) {
        if (key == 11) { // backspace
            appendedString = @"";
        } else {
            appendedString = [NSString stringWithFormat:@"%ld", (long)key];
        }
    } else {
        currentQuantityString = [NSString stringWithFormat:@"%i", [self.ticket.previewRequest.orderQuantity intValue]];
        newQuantityString = [NSString stringWithFormat:@"%ld", (long)key];
        if (key == 11) { // backspace
            appendedString = [currentQuantityString substringToIndex:[currentQuantityString length] - 1];
        } else {
            if ([currentQuantityString isEqualToString:@"0"]) {
                currentQuantityString = @"";
            }
            appendedString = [NSString stringWithFormat:@"%@%@", currentQuantityString, newQuantityString];
        }
    }
    
    self.ticket.previewRequest.orderQuantity = [NSNumber numberWithInt:[appendedString intValue]];
    sharesInput.text = [self.utils formatIntegerToReadablePrice:appendedString];
}

-(void) changeOrderLimitPrice:(NSInteger)key {
    NSString * currentLimitPrice = limitPriceInput.text;

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
    
    self.ticket.previewRequest.orderLimitPrice = [NSNumber numberWithFloat:[newLimitString floatValue]];
    limitPriceInput.text = newLimitString;
}

-(void) changeOrderStopPrice:(NSInteger)key {
    NSString * currentStopPrice = stopPriceInput.text;

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
    
    self.ticket.previewRequest.orderStopPrice = [NSNumber numberWithFloat:[newStopString floatValue]];
    stopPriceInput.text = newStopString;
}

-(void) changeOrderSymbol:(NSString *)symbol {
    self.ticket.previewRequest.orderSymbol = symbol;
    [self populateSymbolDetails];
}

-(void) changeOrderAction: (NSString *) action {
    [orderActionButton setTitle:[self.utils splitCamelCase:action] forState:UIControlStateNormal];
    self.ticket.previewRequest.orderAction = action;
    [self populateSymbolDetails];
}

-(void) changeOrderExpiration: (NSString *) exp {
    if([self.ticket.previewRequest.orderPriceType isEqualToString:@"market"] && [exp isEqualToString:@"gtc"]) {
        self.ticket.previewRequest.orderExpiration = @"day";

        if(![UIAlertController class]) {
            [self showOldErrorAlert:@"Invalid Expiration" withMessage:@"Market orders are Good For The Day only."];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Invalid Expiration"
                                                                            message:@"Market orders are Good For The Day only."
                                                                     preferredStyle:UIAlertControllerStyleAlert];

            alert.modalPresentationStyle = UIModalPresentationPopover;

            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];

            UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
            alertPresentationController.sourceView = self.view;
            alertPresentationController.permittedArrowDirections = 0;
            alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
        }
    }

    if([exp isEqualToString:@"gtc"]) {
        [orderExpirationButton setTitle:@"Good Until Canceled" forState:UIControlStateNormal];
        self.ticket.previewRequest.orderExpiration = @"gtc";
    } else {
        [orderExpirationButton setTitle:@"Good For The Day" forState:UIControlStateNormal];
        self.ticket.previewRequest.orderExpiration = @"day";
    }
}

-(void) changeOrderType: (NSString *) type {
    self.ticket.previewRequest.orderPriceType = type;
    [orderTypeButton setTitle:[self.utils splitCamelCase:type] forState:UIControlStateNormal];

    if([type isEqualToString:@"limit"]){
        [self setToLimitOrder];
    } else if([type isEqualToString:@"stopMarket"]){
        [self setToStopMarketOrder];
    } else if([type isEqualToString:@"stopLimit"]){
        [self setToStopLimitOrder];
    } else {
        [self setToMarketOrder];
    }

    [self checkIfReadyToTrade];
}

-(void) setToMarketOrder {
    self.ticket.previewRequest.orderPriceType = @"market";

    [self changeOrderExpiration:@"day"];
    [self hideExpiration];
    [self hideLimitContainer];
    [self hideStopContainer];
}

-(void) setToLimitOrder {
    [stopPriceInput setHidden:YES];
    [limitPriceInput setHidden:NO];

    [self showExpiration];
    [self showLimitContainer];
    [self hideStopContainer];
}

-(void) setToStopMarketOrder {
    [limitPriceInput setHidden: YES];
    [stopPriceInput setHidden: NO];

    [self showExpiration];
    [self hideLimitContainer];
    [self showStopContainer];
}

-(void) setToStopLimitOrder {
    [stopPriceInput setHidden: NO];
    [limitPriceInput setHidden: NO];

    [self showExpiration];
    [self showLimitContainer];
    [self showStopContainer];
}

-(void) hideLimitContainer {
    [limitPriceInput setHidden: YES];
}

-(void) showLimitContainer {
    [limitPriceInput setHidden: NO];
}

-(void) showStopContainer {
    [stopPriceInput setHidden: NO];
}

-(void) hideStopContainer {
    [stopPriceInput setHidden: YES];
}

-(void) hideExpiration {
    orderExpirationButton.hidden = YES;
    expirationDropdownArrow.hidden = YES;
}

-(void) showExpiration {
    orderExpirationButton.hidden = NO;
    expirationDropdownArrow.hidden = NO;
}


#pragma mark Events

-(IBAction) symbolPressed:(id)sender {
    [self performSegueWithIdentifier:@"TradeToSearch" sender:self];
}
                                          
-(IBAction) refreshPressed:(id)sender {
    [self.view endEditing:YES];
}

-(IBAction) keypadPressed:(id)sender {
    UIButton * button = (UIButton *)sender;
    NSInteger key = button.tag;

    if ([currentFocus isEqualToString: @"shares"]) {
        [self changeOrderQuantity: key];
    }

    if ([currentFocus isEqualToString: @"limit"]) {
        [self changeOrderLimitPrice: key];
    }

    if ([currentFocus isEqualToString: @"stop"]) {
        [self changeOrderStopPrice: key];
    }

    [self checkIfReadyToTrade];
}

-(IBAction) orderActionPressed:(id)sender {
    [self.view endEditing:YES];

    NSArray * options = @[
                          @{@"Buy": @"buy"},
                          @{@"Sell": @"sell"},
                          @{@"Buy to Cover": @"buyToCover"},
                          @{@"Sell Short": @"sellShort"}
                          ];
    
    [self showPicker:@"Order Action" withSelection:self.ticket.previewRequest.orderAction andOptions:options onSelection:^(void) {
        [self changeOrderAction: self.currentSelection];
    }];
}

-(IBAction) orderTypePressed:(id)sender {
    [self.view endEditing:YES];

    NSArray * options = @[
                          @{@"Market": @"market"},
                          @{@"Limit": @"limit"},
                          @{@"Stop Market": @"stopMarket"},
                          @{@"Stop Limit": @"stopLimit"}
                          ];
    
    [self showPicker:@"Order Type" withSelection:self.ticket.previewRequest.orderPriceType andOptions:options onSelection:^(void){
        [self changeOrderType: self.currentSelection];
    }];
}

-(IBAction) brokerLinkPressed:(id)sender {
    [self performSegueWithIdentifier:@"TradeToAccountSelect" sender:self];
}

-(IBAction) orderExpirationPressed:(id)sender {
    [self.view endEditing:YES];

    NSArray * options = @[
                          @{@"Good For The Day": @"day"},
                          @{@"Good Until Canceled": @"gtc"}
                          ];
    
    [self showPicker:@"Order Expiration" withSelection:self.ticket.previewRequest.orderExpiration andOptions:options onSelection:^(void) {
        [self changeOrderExpiration: self.currentSelection];
    }];
}

-(IBAction) previewOrderPressed:(id)sender {
    [self.view endEditing:YES];

    if(readyToTrade) {
        [previewOrderButton enterLoadingState];
        [self sendPreviewRequestWithCompletionBlock:^(TradeItResult* res) {
            [previewOrderButton exitLoadingState];
            [previewOrderButton activate];
        }];
    }
}

-(IBAction) cancelPressed:(id)sender {
    [self.ticket returnToParentApp];
}

-(IBAction) portfolioLinkPressed:(id)sender {
    [self performSegueWithIdentifier:@"OrderToPortfolio" sender:self];
}

-(IBAction) editAccountsPressed:(id)sender {
    [self performSegueWithIdentifier:@"TradeToLogin" sender:self];
}

-(void) acknowledgeAlert {
    [previewOrderButton activate];
}


#pragma mark Navigation

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"TradeToLogin"]) {
        UINavigationController * dest = (UINavigationController *)segue.destinationViewController;
        [self.ticket removeBrokerSelectFromNav: dest];
    }
}


@end
