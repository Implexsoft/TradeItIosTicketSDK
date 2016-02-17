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
#import "TTSDKLoginViewController.h"
#import "TradeItBalanceService.h"
#import "TTSDKPosition.h"
#import "TradeItQuotesResult.h"
#import "TTSDKAccountService.h"


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
    TTSDKTicketController * globalController;
}

@end

@implementation TTSDKTradeViewController



#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];

    utils = [TTSDKUtils sharedUtils];
    globalController = [TTSDKTicketController globalController];

    if (globalController.currentSession.currentAccount) {
        globalController.currentSession.previewRequest.accountNumber = [globalController.currentSession.currentAccount valueForKey:@"accountNumber"];
    }

    if (!globalController.currentSession.isAuthenticated) {
        [globalController.currentSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * res) {
            if ([res isKindOfClass:TradeItAuthenticationResult.class]) {
                [self checkIfReadyToTrade];

                if (globalController.position) {
                    [globalController.position getPositionData:^(TradeItResult * result) {
                        [self populateSymbolDetails];
                    }];
                }
            }
        }];
    }

    [self initConstraints];
    [self uiTweaks];

    if(globalController.currentSession.previewRequest.orderQuantity > 0) {
        [sharesInput setText:[NSString stringWithFormat:@"%i", [globalController.currentSession.previewRequest.orderQuantity intValue]]];
    }

    [self updatePrice];
    [self checkIfReadyToTrade];

    [sharesInput becomeFirstResponder];

    [utils initKeypadWithName:@"TTSDKcalc" intoContainer:keypadContainer onPress:@selector(keypadPressed:) inController:self];
    companyNib = [utils companyDetailsWithName:@"TTSDKCompanyDetailsView" intoContainer:companyDetails inController:self];

    [self setCustomEvents];
    [self refreshPressed:self];

    [self.view setNeedsDisplay];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self populateSymbolDetails];

    TTSDKAccountService * acctService = [[TTSDKAccountService alloc] init];
    [acctService getAccountSummaryFromAccount:globalController.currentSession.currentAccount withCompletionBlock:^(TTSDKAccountSummaryResult * summary) {

    }];

    [globalController retrieveAccountOverview: [globalController.currentSession.currentAccount valueForKey: @"accountNumber"] withCompletionBlock:^(TradeItResult * res) {
        [self populateSymbolDetails];
    }];

    [globalController retrievePositionsFromAccount:globalController.currentSession.currentAccount withCompletionBlock:^(TradeItResult * res) {
        [self populateSymbolDetails];
    }];

    [self changeOrderAction:globalController.currentSession.previewRequest.orderAction];
    [self changeOrderType:globalController.currentSession.previewRequest.orderPriceType];
    [self changeOrderExpiration:globalController.currentSession.previewRequest.orderExpiration];

    if ([utils isSmallScreen] && !uiConfigured) {
        [self configureUIForSmallScreens];
    }

    if (self.refreshAccount) {
        [self refreshToNewAccount];
    }
}

-(void) populateSymbolDetails {
    TTSDKPosition * position = globalController.position;

    [companyNib populateDetailsWithPosition:position];
    [companyNib populateBrokerButtonTitle: globalController.currentSession.broker];

    if ([globalController.currentSession.previewRequest.orderAction isEqualToString: @"buy"]) {
        if (globalController.currentAccountOverview) {
            [companyNib populateSymbolDetail:globalController.currentAccountOverview.buyingPower andSharesOwned:nil];
        } else {
            [companyNib populateSymbolDetail:nil andSharesOwned:nil];
        }
    } else {
        if (globalController.currentPositionsResult) {
            int shares = 0;
            NSArray * currentPositions = globalController.currentPositionsResult.positions;
            for (TradeItPosition * position in currentPositions) {
                if ([position.symbol isEqualToString:globalController.currentSession.previewRequest.orderSymbol]) {
                    shares ++;
                }
            }
            [companyNib populateSymbolDetail:nil andSharesOwned:[NSNumber numberWithInt: shares]];
        } else {
            [companyNib populateSymbolDetail: nil andSharesOwned: nil];
        }
    }

    [self checkIfReadyToTrade];
}

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



#pragma mark - Delegate Methods

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



#pragma mark - Custom UI

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



#pragma mark - Keypad

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



#pragma mark - Account

-(void) refreshToNewAccount {
    [companyNib populateBrokerButtonTitle: [globalController.currentSession.currentAccount valueForKey:@"broker"]];
}



#pragma mark - Order

-(void) checkIfReadyToTrade {
    [self updateEstimatedCost];

    BOOL readyNow = NO;
    NSInteger shares = [sharesInput.text integerValue];

    double limitPrice = [globalController.currentSession.previewRequest.orderLimitPrice doubleValue];
    double stopPrice = [globalController.currentSession.previewRequest.orderStopPrice doubleValue];

    if(shares < 1) {
        readyNow = NO;
    } else if([globalController.currentSession.previewRequest.orderPriceType isEqualToString:@"stopLimit"]) {
        if(limitPrice > 0 && stopPrice > 0) {
            readyNow = YES;
        }
    } else if([globalController.currentSession.previewRequest.orderPriceType isEqualToString:@"market"]) {
        readyNow = YES;
    } else if([globalController.currentSession.previewRequest.orderPriceType isEqualToString:@"stopMarket"]) {
        if(stopPrice > 0) {
            readyNow = YES;
        }
    } else {
        if(limitPrice > 0) {
            readyNow = YES;
        }
    }

    if (!globalController.currentSession.isAuthenticated || !globalController.currentSession.currentAccount) {
        readyNow = NO;
    }

    if(readyNow) {
        [utils styleMainActiveButton:previewOrderButton];
    } else {
        [utils styleMainInactiveButton:previewOrderButton];
    }

    readyToTrade = readyNow;
}

-(void) updateEstimatedCost {
    NSInteger shares = [globalController.currentSession.previewRequest.orderQuantity integerValue];
    double price = [globalController.position.lastPrice doubleValue];

    if([globalController.currentSession.previewRequest.orderPriceType isEqualToString:@"stopMarket"]){
        price = [globalController.currentSession.previewRequest.orderStopPrice doubleValue];
    } else if([globalController.currentSession.previewRequest.orderPriceType containsString:@"imit"]) {
        price = [globalController.currentSession.previewRequest.orderLimitPrice doubleValue];
    }

    double estimatedCost = shares * price;
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: US];

    NSString * formattedNumber = [formatter stringFromNumber: [NSNumber numberWithDouble:estimatedCost]];
    NSString * equalitySign = [globalController.currentSession.previewRequest.orderPriceType containsString:@"arket"] ? @"\u2248" : @"=";
    NSString * actionPostfix = ([globalController.currentSession.previewRequest.orderAction isEqualToString:@"buy"]) ? @"Cost" : @"Proceeds";
    NSString * formattedString = [NSString stringWithFormat:@"Est. %@ %@ %@", actionPostfix, equalitySign, formattedNumber];

    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:formattedString];

    [estimatedCostLabel setAttributedText:attString];
}

-(void) updatePrice {
    double lastPrice = [globalController.position.lastPrice doubleValue];
    NSNumber * changeDollar = globalController.position.todayGainLossDollar;
    NSNumber * changePercentage = globalController.position.todayGainLossPercentage;

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

-(void) changeOrderAction: (NSString *) action {
    [orderActionButton setTitle:[utils splitCamelCase:action] forState:UIControlStateNormal];
    globalController.currentSession.previewRequest.orderAction = action;
    [self populateSymbolDetails];
}

-(void) changeOrderExpiration: (NSString *) exp {
    if([globalController.currentSession.previewRequest.orderPriceType isEqualToString:@"market"] && [exp isEqualToString:@"gtc"]) {
        globalController.currentSession.previewRequest.orderExpiration = @"day";

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
        globalController.currentSession.previewRequest.orderExpiration = @"gtc";
    } else {
        [orderExpirationButton setTitle:@"Good For The Day" forState:UIControlStateNormal];
        globalController.currentSession.previewRequest.orderExpiration = @"day";
    }
}

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
    globalController.currentSession.previewRequest.orderPriceType = @"market";

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
    limitPriceInput.text = [NSString stringWithFormat:@"Limit: %@", [utils formatPriceString: globalController.currentSession.previewRequest.orderLimitPrice]];

    [limitPriceInput sizeToFit];
    limitPricesWidthConstraint.constant = limitPriceInput.frame.size.width;

    [self showExpiration];

    [self showLimitContainer];
}

-(void) setToStopMarketOrder {
    [limitPriceInput setHidden:YES];
    [stopPriceInput setHidden:NO];
    limitPriceInput.text = nil;
    stopPriceInput.text = [NSString stringWithFormat:@"Stop: %@", [utils formatPriceString: globalController.currentSession.previewRequest.orderStopPrice]];

    [stopPriceInput sizeToFit];
    limitPricesWidthConstraint.constant = stopPriceInput.frame.size.width;

    [self showExpiration];

    [self showLimitContainer];
}

-(void) setToStopLimitOrder {
    [stopPriceInput setHidden: NO];
    [limitPriceInput setHidden:NO];
    [limitPriceInput setPlaceholder:@"Limit Price"];
    limitPriceInput.text = [NSString stringWithFormat:@"Limit: %@", [utils formatPriceString: globalController.currentSession.previewRequest.orderLimitPrice]];
    stopPriceInput.text = [NSString stringWithFormat:@"Stop: %@", [utils formatPriceString: globalController.currentSession.previewRequest.orderStopPrice]];

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



#pragma mark - Events

- (IBAction)symbolPressed:(id)sender {
    [self performSegueWithIdentifier:@"TradeToSearch" sender:self];
}
                                          
- (IBAction)refreshPressed:(id)sender {
    [self.view endEditing:YES];

    if(globalController.refreshQuote != nil) {
        //perform network request (most likely) off the main thread
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0),  ^(void){
            globalController.refreshQuote(globalController.position.symbol, ^(double lastPrice, double priceChangeDollar, double priceChangePercentage, NSString * quoteUpdateTime){

                //return to main thread as this triggers a UI change
                dispatch_async(dispatch_get_main_queue(), ^{
                    globalController.position.lastPrice = [NSNumber numberWithDouble:lastPrice];
                    globalController.position.todayGainLossDollar = [NSNumber numberWithDouble:priceChangeDollar];
                    globalController.position.todayGainLossPercentage = [NSNumber numberWithDouble:priceChangePercentage];
                    [self updatePrice];
                });
            });
        });
    } else if(globalController.refreshLastPrice != nil) {
        //perform network request (most likely) off the main thread
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0),  ^(void){
            globalController.refreshLastPrice(globalController.position.symbol, ^(double price){
                //return to main thread as this triggers a UI change
                dispatch_async(dispatch_get_main_queue(), ^{
                    globalController.position.lastPrice = [NSNumber numberWithDouble:price];
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

    if (!globalController.currentSession.previewRequest.orderQuantity) {
        if (key == 11) { // backspace
            appendedString = @"";
        } else {
            appendedString = [NSString stringWithFormat:@"%ld", (long)key];
        }
    } else {
        currentQuantityString = [NSString stringWithFormat:@"%i", [globalController.currentSession.previewRequest.orderQuantity intValue]];
        newQuantityString = [NSString stringWithFormat:@"%ld", (long)key];

        if (key == 11) { // backspace
            appendedString = [currentQuantityString substringToIndex:[currentQuantityString length] - 1];
        } else {
            appendedString = [NSString stringWithFormat:@"%@%@", currentQuantityString, newQuantityString];
        }
    }
    
    globalController.currentSession.previewRequest.orderQuantity = [NSNumber numberWithInt:[appendedString intValue]];
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
        [utils styleLoadingButton:previewOrderButton];
        [self sendPreviewRequest];
    }
}

- (IBAction)cancelPressed:(id)sender {
    [globalController returnToParentApp];
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



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"TradeToLogin"]) {
        [[segue destinationViewController] setCancelToParent: YES];
    }

    defaultEditingCheckComplete = NO;
}



@end
