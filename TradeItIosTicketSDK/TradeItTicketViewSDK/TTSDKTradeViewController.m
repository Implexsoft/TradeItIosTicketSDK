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


@interface TTSDKTradeViewController () {
    __weak IBOutlet UIView * companyDetails;

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
    TTSDKTradeItTicket * globalTicket;

    UIView * loadingView;
}

@end

@implementation TTSDKTradeViewController



#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];

//    orderTypeButton.backgroundColor = [UIColor yellowColor];

    utils = [TTSDKUtils sharedUtils];
    globalTicket = [TTSDKTradeItTicket globalTicket];

    [self initConstraints];

    [utils initKeypadWithName:@"TTSDKcalc" intoContainer:keypadContainer onPress:@selector(keypadPressed:) inController:self];

    keypadContainer.backgroundColor = self.styles.pageBackgroundColor;

    companyNib = [utils companyDetailsWithName:@"TTSDKCompanyDetailsView" intoContainer:companyDetails inController:self];

    companyNib.backgroundColor = self.styles.pageBackgroundColor;

    [self uiTweaks];

    [self setCustomEvents];
    [self refreshPressed:self];

    [self.view setNeedsDisplay];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (globalTicket.quote.symbol == nil || [globalTicket.quote.symbol isEqualToString:@""]) {
        [self performSegueWithIdentifier:@"TradeToSearch" sender: self];
    }

    if (!globalTicket.currentSession.isAuthenticated) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
        if (!loadingView) {
            loadingView = [utils retrieveLoadingOverlayForView:self.view];
            [self.view addSubview: loadingView];
        }
        loadingView.hidden = NO;

        [globalTicket.currentSession authenticateFromViewController:self withCompletionBlock:^(TradeItResult * res) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
            if ([res isKindOfClass:TradeItAuthenticationResult.class]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    loadingView.hidden = YES;
                    [self retrieveQuoteData];
                    [self retrieveAccountSummaryData];
                    [self checkIfReadyToTrade];
                });
            }
        }];
    } else {
        [self retrieveQuoteData];
        [self retrieveAccountSummaryData];
        [self checkIfReadyToTrade];
    }

    if (globalTicket.currentSession.isAuthenticated) {
        [self retrieveQuoteData];
    }

    [self populateSymbolDetails];

    [self changeOrderAction:globalTicket.previewRequest.orderAction];
    [self changeOrderType:globalTicket.previewRequest.orderPriceType];
    [self changeOrderExpiration:globalTicket.previewRequest.orderExpiration];

    [companyNib populateBrokerButtonTitle: globalTicket.currentSession.broker];
}

-(void) populateSymbolDetails {
    [companyNib populateDetailsWithQuote:globalTicket.quote];
    [companyNib populateBrokerButtonTitle: globalTicket.currentSession.broker];

    if ([globalTicket.previewRequest.orderAction isEqualToString: @"buy"]) {
        [companyNib populateSymbolDetail:self.currentPortfolioAccount.balance.buyingPower andSharesOwned:nil];
    } else {

        NSNumber * sharesOwned = @0;

        for (TTSDKPosition * position in self.currentPortfolioAccount.positions) {
            if ([position.symbol isEqualToString:globalTicket.quote.symbol]) {
                sharesOwned = position.quantity;
            }
        }

        [companyNib populateSymbolDetail:nil andSharesOwned: sharesOwned];
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

    [utils styleBorderedUnfocusInput:sharesInput];
    
    previewOrderButton.clipsToBounds = YES;

    orderActionButton.layer.borderColor = utils.activeButtonColor.CGColor;

    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect bounds = CGRectMake(orderActionButton.frame.size.width - 20, (orderActionButton.frame.size.height / 2) - 4, 8, 8); // - 8
    CGFloat radius = bounds.size.width / 2;
    CGFloat a = radius * sqrt((CGFloat)3.0) / 2;
    CGFloat b = radius / 2;
    [path moveToPoint:CGPointMake(0, b)];
    [path addLineToPoint:CGPointMake(a, -radius)];
    [path addLineToPoint:CGPointMake(-a, -radius)];

    [path closePath];
    [path applyTransform:CGAffineTransformMakeTranslation(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    shapeLayer.path = path.CGPath;

    shapeLayer.strokeColor = utils.activeButtonColor.CGColor;
    shapeLayer.fillColor = utils.activeButtonColor.CGColor;
    
    [orderActionButton.layer addSublayer: shapeLayer];

    if(globalTicket.previewRequest.orderQuantity > 0) {
        [sharesInput setText:[NSString stringWithFormat:@"%i", [globalTicket.previewRequest.orderQuantity intValue]]];
    }

    [sharesInput becomeFirstResponder];

    if ([utils isSmallScreen] && !uiConfigured) {
        [self configureUIForSmallScreens];
    }
}

-(void) applyBorder: (UIView *) item {
    item.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
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



#pragma mark - Order

-(void) checkIfReadyToTrade {
    [self updateEstimatedCost];

    BOOL readyNow = NO;

    NSInteger shares = [sharesInput.text integerValue];

    double limitPrice = [globalTicket.previewRequest.orderLimitPrice doubleValue];
    double stopPrice = [globalTicket.previewRequest.orderStopPrice doubleValue];

    if(shares < 1) {
        readyNow = NO;
    } else if([globalTicket.previewRequest.orderPriceType isEqualToString:@"stopLimit"]) {
        if(limitPrice > 0 && stopPrice > 0) {
            readyNow = YES;
        }
    } else if([globalTicket.previewRequest.orderPriceType isEqualToString:@"market"]) {
        readyNow = YES;
    } else if([globalTicket.previewRequest.orderPriceType isEqualToString:@"stopMarket"]) {
        if(stopPrice > 0) {
            readyNow = YES;
        }
    } else {
        if(limitPrice > 0) {
            readyNow = YES;
        }
    }

    if (!globalTicket.currentSession.isAuthenticated || !globalTicket.currentAccount) {
        readyNow = NO;
    }
    
    if (!globalTicket.previewRequest.orderSymbol || [globalTicket.previewRequest.orderSymbol isEqualToString:@""]) {
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
    NSInteger shares = [globalTicket.previewRequest.orderQuantity integerValue];
    double price = [globalTicket.quote.lastPrice doubleValue];

    if([globalTicket.previewRequest.orderPriceType isEqualToString:@"stopMarket"]){
        price = [globalTicket.previewRequest.orderStopPrice doubleValue];
    } else if([globalTicket.previewRequest.orderPriceType containsString:@"imit"]) {
        price = [globalTicket.previewRequest.orderLimitPrice doubleValue];
    }

    double estimatedCost = shares * price;
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: US];

    NSString * formattedNumber = [formatter stringFromNumber: [NSNumber numberWithDouble:estimatedCost]];
    NSString * equalitySign = [globalTicket.previewRequest.orderPriceType containsString:@"arket"] ? @"\u2248" : @"=";
    NSString * actionPostfix = ([globalTicket.previewRequest.orderAction isEqualToString:@"buy"]) ? @"Cost" : @"Proceeds";
    NSString * formattedString = [NSString stringWithFormat:@"Est. %@ %@ %@", actionPostfix, equalitySign, formattedNumber];

    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:formattedString];

    [estimatedCostLabel setAttributedText:attString];
}

-(void) changeOrderSymbol:(NSString *)symbol {
    globalTicket.previewRequest.orderSymbol = symbol;
    [self populateSymbolDetails];
}

-(void) changeOrderAction: (NSString *) action {
    [orderActionButton setTitle:[utils splitCamelCase:action] forState:UIControlStateNormal];
    globalTicket.previewRequest.orderAction = action;
    [self populateSymbolDetails];
}

-(void) changeOrderExpiration: (NSString *) exp {
    if([globalTicket.previewRequest.orderPriceType isEqualToString:@"market"] && [exp isEqualToString:@"gtc"]) {
        globalTicket.previewRequest.orderExpiration = @"day";

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
        globalTicket.previewRequest.orderExpiration = @"gtc";
    } else {
        [orderExpirationButton setTitle:@"Good For The Day" forState:UIControlStateNormal];
        globalTicket.previewRequest.orderExpiration = @"day";
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
    globalTicket.previewRequest.orderPriceType = @"market";

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

    if (globalTicket.previewRequest.orderLimitPrice) {
        limitPriceInput.text = [NSString stringWithFormat:@"Limit: %@", [utils formatPriceString: globalTicket.previewRequest.orderLimitPrice]];
    } else {
        limitPriceInput.text = @"";
    }



    [limitPriceInput sizeToFit];
    limitPricesWidthConstraint.constant = limitPriceInput.frame.size.width;

    [self showExpiration];

    [self showLimitContainer];
}

-(void) setToStopMarketOrder {
    [limitPriceInput setHidden:YES];
    [stopPriceInput setHidden:NO];
    limitPriceInput.text = nil;
    stopPriceInput.text = [NSString stringWithFormat:@"Stop: %@", [utils formatPriceString: globalTicket.previewRequest.orderStopPrice]];

    [stopPriceInput sizeToFit];
    limitPricesWidthConstraint.constant = stopPriceInput.frame.size.width;

    [self showExpiration];

    [self showLimitContainer];
}

-(void) setToStopLimitOrder {
    [stopPriceInput setHidden: NO];
    [limitPriceInput setHidden:NO];
    [limitPriceInput setPlaceholder:@"Limit Price"];
    [stopPriceInput setPlaceholder:@"Stop Price"];
    limitPriceInput.text = @"";
    stopPriceInput.text = @"";

    if (globalTicket.previewRequest.orderLimitPrice) {
        limitPriceInput.text = [NSString stringWithFormat:@"%@", [utils formatPriceString: globalTicket.previewRequest.orderLimitPrice]];;
    } else {
        limitPriceInput.text = @"";
    }

    if (globalTicket.previewRequest.orderStopPrice) {
        stopPriceInput.text = [NSString stringWithFormat:@"%@", [utils formatPriceString: globalTicket.previewRequest.orderStopPrice]];
    } else {
        stopPriceInput.text = @"";
    }

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

    // TODO - implement this
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

    if (!globalTicket.previewRequest.orderQuantity) {
        if (key == 11) { // backspace
            appendedString = @"";
        } else {
            appendedString = [NSString stringWithFormat:@"%ld", (long)key];
        }
    } else {
        currentQuantityString = [NSString stringWithFormat:@"%i", [globalTicket.previewRequest.orderQuantity intValue]];
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

    globalTicket.previewRequest.orderQuantity = [NSNumber numberWithInt:[appendedString intValue]];
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
    alert.modalPresentationStyle = UIModalPresentationPopover;

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

    UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
    alertPresentationController.sourceView = self.view;
    alertPresentationController.permittedArrowDirections = 0;
    alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
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

    alert.modalPresentationStyle = UIModalPresentationPopover;

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

    UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
    alertPresentationController.sourceView = self.view;
    alertPresentationController.permittedArrowDirections = 0;
    alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
}

-(void) showOldOrderType {
    self.pickerTitles = @[@"Market",@"Limit",@"Stop Market",@"Stop Limit"];
    self.pickerValues = @[@"market",@"limit",@"stopMarket",@"stopLimit"];
    NSString * currentSelection = globalTicket.previewRequest.orderPriceType;

    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Order Action"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 1) {
            [self changeOrderType: currentSelection];
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];

        if([globalTicket.previewRequest.orderPriceType isEqualToString:@"stopLimit"]){
            [self.currentPicker selectRow:3 inComponent:0 animated:NO];
        } else if([globalTicket.previewRequest.orderPriceType isEqualToString:@"stopMarket"]) {
            [self.currentPicker selectRow:2 inComponent:0 animated:NO];
        } else if([globalTicket.previewRequest.orderPriceType isEqualToString:@"limit"]) {
            [self.currentPicker selectRow:1 inComponent:0 animated:NO];
        }
    });
}

//- (IBAction)orderTypePressed:(id)sender {
//    [self.view endEditing:YES];
//    if(![UIAlertController class]) {
//        [self showOldOrderType];
//        return;
//    }
//    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Order Type"
//                                                                   message:nil
//                                                            preferredStyle:UIAlertControllerStyleActionSheet];
//
//    UIAlertAction* marketAction = [UIAlertAction actionWithTitle:@"Market" style:UIAlertActionStyleDefault
//                                                         handler:^(UIAlertAction * action) { [self changeOrderType:@"market"]; }];
//    UIAlertAction* limitAction = [UIAlertAction actionWithTitle:@"Limit" style:UIAlertActionStyleDefault
//                                                        handler:^(UIAlertAction * action) { [self changeOrderType:@"limit"]; }];
//    UIAlertAction* stopMarketAction = [UIAlertAction actionWithTitle:@"Stop Market" style:UIAlertActionStyleDefault
//                                                             handler:^(UIAlertAction * action) { [self changeOrderType:@"stopMarket"]; }];
//    UIAlertAction* stopLimitAction = [UIAlertAction actionWithTitle:@"Stop Limit" style:UIAlertActionStyleDefault
//                                                            handler:^(UIAlertAction * action) { [self changeOrderType:@"stopLimit"]; }];
//    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
//                                                          handler:^(UIAlertAction * action) {}];
//    [alert addAction:marketAction];
//    [alert addAction:limitAction];
//    [alert addAction:stopMarketAction];
//    [alert addAction:stopLimitAction];
//    [alert addAction:cancelAction];
//    [self presentViewController:alert animated:YES completion:nil];
//}

- (IBAction)previewOrderPressed:(id)sender {
    [self.view endEditing:YES];

    if(readyToTrade) {
        [utils styleLoadingButton:previewOrderButton];
        [self sendPreviewRequest];
    }
}

- (IBAction)cancelPressed:(id)sender {
    [globalTicket returnToParentApp];
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
