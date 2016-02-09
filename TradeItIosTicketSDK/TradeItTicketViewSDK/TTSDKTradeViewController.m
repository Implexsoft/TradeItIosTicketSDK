//
//  TTSDKTradeViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/29/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKTradeViewController.h"
#import "TTSDKOrderTypeSelectionViewController.h"
#import "TTSDKOrderTypeInputViewController.h"
#import "TTSDKReviewScreenViewController.h"
#import "TTSDKCompanyDetails.h"


@interface TTSDKTradeViewController () {
    __weak IBOutlet UIView * companyDetails;
    __weak IBOutlet UILabel * companyNameLabel;
    __weak IBOutlet UILabel * lastPriceLabel;
    __weak IBOutlet UILabel *performanceLabel;

    __weak IBOutlet UIButton * orderActionButton;
    __weak IBOutlet UITextField * sharesInput;
    __weak IBOutlet UILabel * estimatedCostLabel;

    __weak IBOutlet UIButton * orderTypeButton;
    __weak IBOutlet UIView * limitPricesView;
    __weak IBOutlet UITextField *stopPriceInput;
    __weak IBOutlet UITextField *limitPriceInput;

    __weak IBOutlet UIButton * orderExpirationButton;

    __weak IBOutlet UIButton * previewOrderButton;

    __weak IBOutlet UIView * keypadContainer;
    __weak IBOutlet UIView * orderView;
    __weak IBOutlet UIView *containerView;

    NSLayoutConstraint * zeroHeightConstraint;
    NSLayoutConstraint * fullHeightConstraint;

    __weak IBOutlet NSLayoutConstraint *keypadTopConstraint;
    __weak IBOutlet NSLayoutConstraint *limitPricesWidthConstraint;

    BOOL readyToTrade;
    UIView * keypad;

    TTSDKCompanyDetails * companyNib;

    BOOL uiConfigured;
    BOOL defaultEditingCheckComplete;
    
    TTSDKUtils * utils;
}

@end

@implementation TTSDKTradeViewController


/*** Delegate Methods ***/

- (void)viewDidLoad {
    [super viewDidLoad];

    utils = [TTSDKUtils sharedUtils];

    [self initConstraints];
    [self uiTweaks];

    if (!self.globalController.tradeRequest) {
        [self.globalController createInitialTradeRequest];
    }

    if(self.globalController.tradeRequest.orderQuantity > 0) {
        [sharesInput setText:[NSString stringWithFormat:@"%i", [self.globalController.tradeRequest.orderQuantity intValue]]];
    }

    [self updatePrice];
    [self checkIfReadyToTrade];

    [sharesInput becomeFirstResponder];

    [utils initKeypadWithName:@"TTSDKcalc" intoContainer:keypadContainer onPress:@selector(keypadPressed:) inController:self];
    companyNib = [utils companyDetailsWithName:@"TTSDKCompanyDetailsView" intoContainer:companyDetails inController:self];

    TradeItPosition * position = self.globalController.position;
    [companyNib populateDetailsWithSymbol:position.symbol andLastPrice:position.lastPrice andChange:position.todayGainLossDollar andChangePct:position.todayGainLossPercentage];
    [companyNib populateBrokerButtonTitle:self.globalController.currentBroker];

    [self setCustomEvents];
    [self refreshPressed:self];

    [self.view setNeedsDisplay];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self changeOrderAction:self.globalController.tradeRequest.orderAction];
    [self changeOrderType:self.globalController.tradeRequest.orderPriceType];
    [self changeOrderExpiration:self.globalController.tradeRequest.orderExpiration];

    if ([utils isSmallScreen] && !uiConfigured) {
        [self configureUIForSmallScreens];
    }
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
    borderLayer.backgroundColor = utils.activeButtonColor.CGColor;
    [keypadContainer.layer addSublayer:borderLayer];

    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:keypadContainer.bounds];
    keypadContainer.layer.masksToBounds = NO;
    keypadContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    keypadContainer.layer.shadowOffset = CGSizeMake(0.0f, -0.5f);
    keypadContainer.layer.shadowOpacity = 0.5f;
    keypadContainer.layer.shadowPath = shadowPath.CGPath;
    keypadContainer.layer.zPosition = 100;

    [self hideKeypad];
}

-(void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([utils isSmallScreen]) {
        [self hideKeypad];
    }
}

-(BOOL) isKeypadVisible {
    if (keypadContainer.layer.opacity < 1) {
        return NO;
    } else {
        return YES;
    }
}

-(void) showKeypad {
    if ([self isKeypadVisible] || ![utils isSmallScreen]) {
        return;
    }

    CATransform3D currentTransform = keypadContainer.layer.transform;
    [UIView animateWithDuration:0.5f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         keypadContainer.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeTranslation(0.0f, -200.0f, 0.0f));
                         keypadContainer.layer.opacity = 1.0f;
                     }
                     completion:^(BOOL finished) {
                     }
     ];
}

-(void) hideKeypad {
    if (![self isKeypadVisible] || ![utils isSmallScreen]) {
        return;
    }

    CATransform3D currentTransform = keypadContainer.layer.transform;
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         keypadContainer.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeTranslation(0.0f, 200.0f, 1.0f));
                         keypadContainer.layer.opacity = 0.0f;
                     }
                     completion:^(BOOL finished) {
                     }
     ];
}

#pragma mark - Initialization

-(void) initConstraints {
    zeroHeightConstraint = [NSLayoutConstraint
                            constraintWithItem:limitPricesView
                            attribute:NSLayoutAttributeHeight
                            relatedBy:NSLayoutRelationEqual
                            toItem:NSLayoutAttributeNotAnAttribute
                            attribute:NSLayoutAttributeHeight
                            multiplier:1
                            constant:0];
    zeroHeightConstraint.priority = 900;

    fullHeightConstraint = [NSLayoutConstraint
                            constraintWithItem:limitPricesView
                            attribute:NSLayoutAttributeHeight
                            relatedBy:NSLayoutRelationEqual
                            toItem:NSLayoutAttributeNotAnAttribute
                            attribute:NSLayoutAttributeHeight
                            multiplier:1
                            constant:35];
    fullHeightConstraint.priority = 900;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (![utils isSmallScreen]) {
        return NO;
    }

    if ([textField.placeholder isEqualToString:@"Shares"] && defaultEditingCheckComplete) {
        [self showKeypad];
    } else {
        defaultEditingCheckComplete = YES;
    }

    return NO;
}

-(void) uiTweaks { // things that can't be done in Storyboard
    [self applyBorder:(UIView *)sharesInput];
    [self applyBorder:(UIView *)orderActionButton];

    [utils styleBorderedFocusInput:sharesInput];

    previewOrderButton.clipsToBounds = YES;
    orderActionButton.layer.borderColor = utils.activeButtonColor.CGColor;
}

-(void) applyBorder: (UIView *) item {
    item.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    item.layer.borderWidth = 1;
    item.layer.cornerRadius = item.frame.size.height / 2;
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



#pragma mark - Order State

-(void) checkIfReadyToTrade {
    [self updateEstimatedCost];

    BOOL readyNow = NO;
    NSInteger shares = [sharesInput.text integerValue];

    double limitPrice = [self.globalController.tradeRequest.orderLimitPrice doubleValue];
    double stopPrice = [self.globalController.tradeRequest.orderStopPrice doubleValue];

    if(shares < 1) {
        readyNow = NO;
    } else if([self.globalController.tradeRequest.orderPriceType isEqualToString:@"stopLimit"]) {
        if(limitPrice > 0 && stopPrice > 0) {
            readyNow = YES;
        }
    } else if([self.globalController.tradeRequest.orderPriceType isEqualToString:@"market"]) {
        readyNow = YES;
    } else if([self.globalController.tradeRequest.orderPriceType isEqualToString:@"stopMarket"]) {
        if(stopPrice > 0) {
            readyNow = YES;
        }
    } else {
        if(limitPrice > 0) {
            readyNow = YES;
        }
    }

    if(readyNow) {
        [utils styleMainActiveButton:previewOrderButton];
    } else {
        [utils styleMainInactiveButton:previewOrderButton];
    }

    readyToTrade = readyNow;
}



#pragma mark - Order Editing

-(void) updateEstimatedCost {
    NSInteger shares = [self.globalController.tradeRequest.orderQuantity integerValue];
    double price = [self.globalController.position.lastPrice doubleValue];

    if([self.globalController.tradeRequest.orderPriceType isEqualToString:@"stopMarket"]){
        price = [self.globalController.tradeRequest.orderStopPrice doubleValue];
    } else if([self.globalController.tradeRequest.orderPriceType containsString:@"imit"]) {
        price = [self.globalController.tradeRequest.orderLimitPrice doubleValue];
    }

    double estimatedCost = shares * price;
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: US];

    NSString * equalitySign = [self.globalController.tradeRequest.orderPriceType containsString:@"arket"] ? @"\u2248" : @"=";
    NSString * formattedNumber = [formatter stringFromNumber: [NSNumber numberWithDouble:estimatedCost]];
    NSString * formattedString = [NSString stringWithFormat:@"%@ %@ %@", @"Est. Cost", equalitySign, formattedNumber];

    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:formattedString];

    [estimatedCostLabel setAttributedText:attString];
}

-(void) updatePrice {
    double lastPrice = [self.globalController.position.lastPrice doubleValue];
    NSNumber * changeDollar = self.globalController.position.todayGainLossDollar;
    NSNumber * changePercentage = self.globalController.position.todayGainLossPercentage;

    NSMutableAttributedString * finalString;

    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:US];

    NSString * lastPriceString = [formatter stringFromNumber:[NSNumber numberWithDouble:lastPrice]];
    finalString = [[NSMutableAttributedString alloc] initWithString:lastPriceString];

    lastPriceLabel.text = lastPriceString;

    if(changeDollar != nil) {
        if([changeDollar doubleValue] == 0) {
            [finalString appendAttributedString:[[NSAttributedString alloc] initWithString:@" $0.00"]];
        } else {
            NSAttributedString * attString = [utils getColoredString:changeDollar withFormat:NSNumberFormatterCurrencyStyle];

            [finalString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            [finalString appendAttributedString:(NSAttributedString *) attString];
        }
    }

    if(changePercentage != nil) {
        if([changePercentage doubleValue] == 0) {
            [finalString appendAttributedString:[[NSAttributedString alloc] initWithString:@" $0.00"]];
        } else {
            NSAttributedString * attString = [utils getColoredString:changePercentage withFormat:NSNumberFormatterDecimalStyle];

            [finalString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            [finalString appendAttributedString:(NSAttributedString *) attString];
        }
    }

    performanceLabel.attributedText = (NSAttributedString *) finalString;
}

// ORDER ACTION

-(void) changeOrderAction: (NSString *) action {
    [orderActionButton setTitle:[utils splitCamelCase:action] forState:UIControlStateNormal];
    self.globalController.tradeRequest.orderAction = action;
}

// ORDER EXPIRATION

-(void) changeOrderExpiration: (NSString *) exp {
    if([self.globalController.tradeRequest.orderPriceType isEqualToString:@"market"] && [exp isEqualToString:@"gtc"]) {
        self.globalController.tradeRequest.orderExpiration = @"day";

        if(![UIAlertController class]) {
            [self showOldErrorAlert:@"Invalid Expiration" withMessage:@"Market orders are Good For The Day only."];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Invalid Expiration"
                                                                            message:@"Market orders are Good For The Day only."
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }

    if([exp isEqualToString:@"gtc"]) {
        [orderExpirationButton setTitle:@"Good Until Canceled" forState:UIControlStateNormal];
        self.globalController.tradeRequest.orderExpiration = @"gtc";
    } else {
        [orderExpirationButton setTitle:@"Good For The Day" forState:UIControlStateNormal];
        self.globalController.tradeRequest.orderExpiration = @"day";
    }
}

// ORDER TYPE

-(void) changeOrderType: (NSString *) type {
    [orderTypeButton setTitle:[utils splitCamelCase:type] forState:UIControlStateNormal];

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
    self.globalController.tradeRequest.orderPriceType = @"market";

    [self changeOrderExpiration:@"day"];
    [self hideExpiration];

    limitPriceInput.text = nil;
    stopPriceInput.text = nil;
    [self hideLimitContainer];
}

-(void) setToLimitOrder {
    [stopPriceInput setHidden:YES];
    [limitPriceInput setHidden:NO];
    [limitPriceInput setPlaceholder:@"Limit Price"];
    stopPriceInput.text = nil;
    limitPriceInput.text = [NSString stringWithFormat:@"Limit: %@", [utils formatPriceString: self.globalController.tradeRequest.orderLimitPrice]];

    [limitPriceInput sizeToFit];
    limitPricesWidthConstraint.constant = limitPriceInput.frame.size.width;

    [self showExpiration];

    [self showLimitContainer];
}

-(void) setToStopMarketOrder {
    [limitPriceInput setHidden:YES];
    [stopPriceInput setHidden:NO];
    limitPriceInput.text = nil;
    stopPriceInput.text = [NSString stringWithFormat:@"Stop: %@", [utils formatPriceString: self.globalController.tradeRequest.orderStopPrice]];

    [stopPriceInput sizeToFit];
    limitPricesWidthConstraint.constant = stopPriceInput.frame.size.width;

    [self showExpiration];

    [self showLimitContainer];
}

-(void) setToStopLimitOrder {
    [stopPriceInput setHidden: NO];
    [limitPriceInput setHidden:NO];
    [limitPriceInput setPlaceholder:@"Limit Price"];
    limitPriceInput.text = [NSString stringWithFormat:@"Limit: %@", [utils formatPriceString: self.globalController.tradeRequest.orderLimitPrice]];
    stopPriceInput.text = [NSString stringWithFormat:@"Stop: %@", [utils formatPriceString: self.globalController.tradeRequest.orderStopPrice]];

    [limitPriceInput sizeToFit];
    [stopPriceInput sizeToFit];
    limitPricesWidthConstraint.constant = limitPriceInput.frame.size.width + stopPriceInput.frame.size.width + 20.0f;

    [self showExpiration];

    [self showLimitContainer];
}

-(void) hideLimitContainer {
    [self.view removeConstraint:fullHeightConstraint];
    [self.view addConstraint:zeroHeightConstraint];
    [limitPriceInput setHidden:YES];
    [stopPriceInput setHidden:YES];
}

-(void) showLimitContainer {
    [self.view removeConstraint:zeroHeightConstraint];
    [self.view addConstraint:fullHeightConstraint];
}

-(void) hideExpiration {
    orderExpirationButton.hidden = YES;
}

-(void) showExpiration {
    orderExpirationButton.hidden = NO;
}



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"TradeToLogin"]) {
        [[segue destinationViewController] setCancelToParent: YES];
    }

    defaultEditingCheckComplete = NO;
}



#pragma mark - Events

- (IBAction)symbolPressed:(id)sender {
    [self performSegueWithIdentifier:@"TradeToSymbolSearch" sender:self];
}
                                          
- (IBAction)refreshPressed:(id)sender {
    [self.view endEditing:YES];

    if(self.globalController.refreshQuote != nil) {
        //perform network request (most likely) off the main thread
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0),  ^(void){
            self.globalController.refreshQuote(self.globalController.position.symbol, ^(double lastPrice, double priceChangeDollar, double priceChangePercentage, NSString * quoteUpdateTime){

                //return to main thread as this triggers a UI change
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.globalController.position.lastPrice = [NSNumber numberWithDouble:lastPrice];
                    self.globalController.position.todayGainLossDollar = [NSNumber numberWithDouble:priceChangeDollar];
                    self.globalController.position.todayGainLossPercentage = [NSNumber numberWithDouble:priceChangePercentage];
                    [self updatePrice];
                });
            });
        });
    } else if(self.globalController.refreshLastPrice != nil) {
        //perform network request (most likely) off the main thread
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0),  ^(void){
            self.globalController.refreshLastPrice(self.globalController.position.symbol, ^(double price){
                //return to main thread as this triggers a UI change
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.globalController.position.lastPrice = [NSNumber numberWithDouble:price];
                    [self updatePrice];
                });
            });
        });
    }
}

- (IBAction)keypadPressed:(id)sender {
    UIButton * button = sender;
    NSInteger key = button.tag;

    if (key == 10) { // decimal key - not allowed for quantity
        return;
    }

    NSString * currentQuantityString;
    NSString * newQuantityString;
    NSString * appendedString;

    if (!self.globalController.tradeRequest.orderQuantity) {
        if (key == 11) { // backspace
            appendedString = @"";
        } else {
            appendedString = [NSString stringWithFormat:@"%ld", (long)key];
        }
    } else {
        currentQuantityString = [NSString stringWithFormat:@"%i", [self.globalController.tradeRequest.orderQuantity intValue]];
        newQuantityString = [NSString stringWithFormat:@"%ld", (long)key];

        if (key == 11) { // backspace
            appendedString = [currentQuantityString substringToIndex:[currentQuantityString length] - 1];
        } else {
            appendedString = [NSString stringWithFormat:@"%@%@", currentQuantityString, newQuantityString];
        }
    }
    
    self.globalController.tradeRequest.orderQuantity = [NSNumber numberWithInt:[appendedString intValue]];
    sharesInput.text = [utils formatIntegerToReadablePrice:appendedString];

    [self checkIfReadyToTrade];
}

- (IBAction)orderActionPressed:(id)sender {
    [self.view endEditing:YES];

    if(![UIAlertController class]) {
        [self showOldOrderAction];
        return;
    }

    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Order Action"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction * buyAction = [UIAlertAction actionWithTitle:@"Buy" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) { [self changeOrderAction:@"buy"]; }];
    UIAlertAction * sellAction = [UIAlertAction actionWithTitle:@"Sell" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) { [self changeOrderAction:@"sell"]; }];
    UIAlertAction * sellShortAction = [UIAlertAction actionWithTitle:@"Sell Short" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) { [self changeOrderAction:@"sellShort"]; }];
    UIAlertAction * buyToCoverAction = [UIAlertAction actionWithTitle:@"Buy to Cover" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) { [self changeOrderAction:@"buyToCover"]; }];
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];

    [alert addAction:buyAction];
    [alert addAction:sellAction];
    [alert addAction:sellShortAction];
    [alert addAction:buyToCoverAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)orderTypePressed:(id)sender {
    [self.view endEditing:YES];
    [self performSegueWithIdentifier:@"TradeToOrderTypeSelection" sender:self];
}

-(IBAction)brokerLinkPressed:(id)sender {
    [self performSegueWithIdentifier:@"TradeToAccountSelect" sender:self];
}

- (IBAction)orderExpirationPressed:(id)sender {
    [self.view endEditing:YES];

    if(![UIAlertController class]) {
        [self showOldOrderExp];
        return;
    }

    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Order Expiration"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction * dayAction = [UIAlertAction actionWithTitle:@"Good For The Day" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) { [self changeOrderExpiration:@"day"]; }];
    UIAlertAction * gtcAction = [UIAlertAction actionWithTitle:@"Good Until Canceled" style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) { [self changeOrderExpiration:@"gtc"]; }];
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];

    [alert addAction:dayAction];
    [alert addAction:gtcAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)previewOrderPressed:(id)sender {
    [self.view endEditing:YES];

    if(readyToTrade) {
        self.globalController.tradeRequest.orderQuantity = [NSNumber numberWithInt:[[sharesInput text] intValue]];

        if([self.globalController.tradeRequest.orderPriceType isEqualToString:@"stopLimit"]) {
            self.globalController.tradeRequest.orderLimitPrice = [NSNumber numberWithDouble:[utils numberFromPriceString:limitPriceInput.text]];
            self.globalController.tradeRequest.orderStopPrice = [NSNumber numberWithDouble:[utils numberFromPriceString:stopPriceInput.text]];
        } else if([self.globalController.tradeRequest.orderPriceType isEqualToString:@"stopMarket"]) {
            self.globalController.tradeRequest.orderStopPrice = [NSNumber numberWithDouble:[utils numberFromPriceString:limitPriceInput.text]];
        } else if([self.globalController.tradeRequest.orderPriceType isEqualToString:@"limit"]) {
            self.globalController.tradeRequest.orderLimitPrice = [NSNumber numberWithDouble:[utils numberFromPriceString:limitPriceInput.text]];
        }

        [utils styleLoadingButton:previewOrderButton];
        [self sendReviewRequest];
    }
}

- (IBAction)cancelPressed:(id)sender {
    [self.globalController returnToParentApp];
}

- (IBAction)portfolioLinkPressed:(id)sender {
    [self performSegueWithIdentifier:@"OrderToPortfolio" sender:self];
}

- (IBAction)editAccountsPressed:(id)sender {
    [self performSegueWithIdentifier:@"TradeToLogin" sender:self];
}

-(void) acknowledgeAlert {
    [utils styleMainActiveButton:previewOrderButton];
}



@end
