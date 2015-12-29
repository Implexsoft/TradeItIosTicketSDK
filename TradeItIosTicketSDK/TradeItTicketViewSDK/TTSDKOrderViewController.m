//
//  AdvCalculatorViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/29/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKOrderViewController.h"
#import "TTSDKOrderTypeSelectionViewController.h"
#import "TTSDKOrderTypeInputViewController.h"
#import "TTSDKReviewScreenViewController.h"
#import "TTSDKCompanyDetails.h"
#import "TTSDKHelper.h"

@interface TTSDKOrderViewController () {
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

    BOOL readyToTrade;

    UIView * keypad;

    NSArray * pickerTitles;
    NSArray * pickerValues;
    UIPickerView * currentPicker;
    NSString * currentSelection;
    NSArray * questionOptions;
    NSDictionary * currentAccount;

    TTSDKCompanyDetails * companyNib;

    TTSDKHelper * helper;
}

@end

@implementation TTSDKOrderViewController


/*** Delegate Methods ***/

- (void)viewDidLoad {
    self.advMode = YES;
    [super viewDidLoad];

    helper = [TTSDKHelper sharedHelper];

    [self initConstraints];
    [self uiTweaks];

    if(self.tradeSession.orderInfo.quantity > 0) {
        [sharesInput setText:[NSString stringWithFormat:@"%i", self.tradeSession.orderInfo.quantity]];
    }

    [self updatePrice];
    [self checkIfReadyToTrade];

    [sharesInput becomeFirstResponder];

    [helper initKeypadWithName:@"TTSDKcalc" intoContainer:keypadContainer onPress:@selector(keypadPressed:) inController:self];
    companyNib = [helper companyDetailsWithName:@"TTSDKCompanyDetailsView" intoContainer:companyDetails inController:self];
    [companyNib populateDetailsWithSymbol:self.tradeSession.orderInfo.symbol andLastPrice:[NSNumber numberWithDouble:self.tradeSession.lastPrice] andChange:self.tradeSession.priceChangeDollar andChangePct:self.tradeSession.priceChangePercentage];

    [self setCustomEvents];
    [self refreshPressed:self];

    [self.view setNeedsDisplay];
}

-(void) viewWillAppear:(BOOL)animated {
    self.advMode = YES;
    [super viewWillAppear:animated];

    [self changeOrderAction:self.tradeSession.orderInfo.action];
    [self changeOrderType:self.tradeSession.orderInfo.price.type];
    [self changeOrderExpiration:self.tradeSession.orderInfo.expiration];

    [self setBroker];

    [[self navigationItem] setTitle: [TTSDKTradeItTicket getBrokerDisplayString:self.tradeSession.broker]];
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
    return NO;
}

-(void) uiTweaks { // things that can't be done in Storyboard
    [self applyBorder:(UIView *)sharesInput];
    [self applyBorder:(UIView *)orderActionButton];

    [helper styleBorderedFocusInput:sharesInput];

    previewOrderButton.clipsToBounds = YES;
    orderActionButton.layer.borderColor = helper.inactiveButtonColor.CGColor;
}

-(void) applyBorder: (UIView *) item {
    item.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    item.layer.borderWidth = 1;
    item.layer.cornerRadius = item.frame.size.height / 2;
}

-(void) setCustomEvents {
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

    double limitPrice = [helper numberFromPriceString:limitPriceInput.text];
    double stopPrice = [helper numberFromPriceString:stopPriceInput.text];

    if(shares < 1) {
        readyNow = NO;
    } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"stopLimitOrder"]) {
        if(limitPrice > 0 && stopPrice > 0) {
            readyNow = YES;
        }
    } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"market"]) {
        readyNow = YES;
    } else {
        if(limitPrice > 0) {
            readyNow = YES;
        }
    }

    if(readyNow) {
        [helper styleMainActiveButton:previewOrderButton];
    } else {
        [helper styleMainInactiveButton:previewOrderButton];
    }

    readyToTrade = readyNow;
}



#pragma mark - Order Editing

-(void) updateEstimatedCost {
    NSInteger shares = self.tradeSession.orderInfo.quantity;
    double price = self.tradeSession.lastPrice;

    if([self.tradeSession.orderInfo.price.type isEqualToString:@"stopMarket"]){
        price = [self.tradeSession.orderInfo.price.stopPrice doubleValue];
    } else if([TTSDKTradeItTicket containsString:self.tradeSession.orderInfo.price.type searchString:@"imit"]) {
        price = [self.tradeSession.orderInfo.price.limitPrice doubleValue];
    }

    double estimatedCost = shares * price;
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: US];

    NSString * equalitySign = [TTSDKTradeItTicket containsString:self.tradeSession.orderInfo.price.type searchString:@"arket"] ? @"\u2248" : @"=";
    NSString * formattedNumber = [formatter stringFromNumber: [NSNumber numberWithDouble:estimatedCost]];
    NSString * formattedString = [NSString stringWithFormat:@"%@ %@ %@", @"Est. Cost", equalitySign, formattedNumber];

    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:formattedString];

    [estimatedCostLabel setAttributedText:attString];
}

-(void) updatePrice {
    double lastPrice = self.tradeSession.lastPrice;
    NSNumber * changeDollar = self.tradeSession.priceChangeDollar;
    NSNumber * changePercentage = self.tradeSession.priceChangePercentage;

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
            NSAttributedString * attString = [helper getColoredString:changeDollar withFormat:NSNumberFormatterCurrencyStyle];

            [finalString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            [finalString appendAttributedString:(NSAttributedString *) attString];
        }
    }

    if(changePercentage != nil) {
        if([changePercentage doubleValue] == 0) {
            [finalString appendAttributedString:[[NSAttributedString alloc] initWithString:@" $0.00"]];
        } else {
            NSAttributedString * attString = [helper getColoredString:changePercentage withFormat:NSNumberFormatterDecimalStyle];

            [finalString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            [finalString appendAttributedString:(NSAttributedString *) attString];
        }
    }

    performanceLabel.attributedText = (NSAttributedString *) finalString;
}

// CHANGING ORDER ACTION
-(void) changeOrderAction: (NSString *) action {
    [orderActionButton setTitle:[TTSDKTradeItTicket splitCamelCase:action] forState:UIControlStateNormal];
    self.tradeSession.orderInfo.action = action;

    orderActionButton.layer.borderColor = helper.inactiveButtonColor.CGColor;
}

// CHANGING ORDER EXPIRATION
-(void) changeOrderExpiration: (NSString *) exp {
    if([self.tradeSession.orderInfo.price.type isEqualToString:@"market"] && [exp isEqualToString:@"gtc"]) {
        self.tradeSession.orderInfo.expiration = @"day";

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
        self.tradeSession.orderInfo.expiration = @"gtc";
    } else {
        [orderExpirationButton setTitle:@"Good For The Day" forState:UIControlStateNormal];
        self.tradeSession.orderInfo.expiration = @"day";
    }
}

// CHANGING ORDER TYPE

-(void) changeOrderType: (NSString *) type {
    [orderTypeButton setTitle:[TTSDKTradeItTicket splitCamelCase:type] forState:UIControlStateNormal];

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
    self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initMarket];
    [self changeOrderExpiration:@"day"];
    [self hideLimitContainer];
    limitPriceInput.text = nil;
    stopPriceInput.text = nil;
}

-(void) setToLimitOrder {
    [stopPriceInput setHidden:YES];
    [limitPriceInput setHidden:NO];
    [limitPriceInput setPlaceholder:@"Limit Price"];
    stopPriceInput.text = nil;

    limitPriceInput.text = [helper formatPriceString: self.tradeSession.orderInfo.price.limitPrice];

    [self showLimitContainer];
}

-(void) setToStopMarketOrder {
    [limitPriceInput setHidden:YES];
    [stopPriceInput setHidden:NO];
    limitPriceInput.text = nil;

    stopPriceInput.text = [helper formatPriceString: self.tradeSession.orderInfo.price.stopPrice];

    [self showLimitContainer];
}

-(void) setToStopLimitOrder {
    [stopPriceInput setHidden: NO];
    [limitPriceInput setHidden:NO];
    [limitPriceInput setPlaceholder:@"Limit Price"];
    limitPriceInput.text = [helper formatPriceString: self.tradeSession.orderInfo.price.limitPrice];
    stopPriceInput.text = [helper formatPriceString: self.tradeSession.orderInfo.price.stopPrice];
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



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"CalculatorToOrderTypeSelection"]) {
        TTSDKOrderTypeSelectionViewController * dest = [segue destinationViewController];

        [dest setTradeSession: self.tradeSession];
    } else if([segue.identifier isEqualToString:@"advCalculatorToBrokerSelectDetail"]) {
        [[segue destinationViewController] setCancelToParent: YES];
    } else if([segue.identifier isEqualToString:@"CalculatorToReview"]) {
        [[segue destinationViewController] setResult: self.reviewResult];
    }

    [[segue destinationViewController] setTradeSession: self.tradeSession];
}

-(IBAction) unwindToAdvCalc:(UIStoryboardSegue *)segue {
    NSString * symbol = [[[self tradeSession] orderInfo] symbol];
    NSString * publisherApp = [[self tradeSession] publisherApp];
    NSString * broker = [[self tradeSession] broker];
    TradeItAuthenticationInfo * creds = [[self tradeSession] authenticationInfo];

    [[self tradeSession] reset];
    [[[self tradeSession] orderInfo] setSymbol: symbol];
    [[self tradeSession] setPublisherApp: publisherApp];
    [[self tradeSession] setBroker: broker];
    [[self tradeSession] setAuthenticationInfo: creds];
}

- (IBAction)settingsPressed:(id)sender {
    CATransform3D currentTransform = containerView.layer.transform;

    if (containerView.layer.opacity < 1) {

        [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             containerView.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeTranslation(0.0f, -180.0f, 0.0f));
                             containerView.layer.opacity = 1.0f;
                         }
                         completion:^(BOOL finished) {
                         }
         ];

    } else {

        [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                         animations:^{
                             containerView.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeTranslation(0.0f, 180.0f, 1.0f));
                             containerView.layer.opacity = 0.95f;
                         }
                         completion:^(BOOL finished) {
                         }
         ];

    }
}



#pragma mark - Events

- (IBAction)symbolPressed:(id)sender {
    [self performSegueWithIdentifier:@"CalculatorToSymbolSearch" sender:self];
}
                                          
- (IBAction)refreshPressed:(id)sender {
    [self.view endEditing:YES];

    if(self.tradeSession.refreshQuote != nil) {
        //perform network request (most likely) off the main thread
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0),  ^(void){
            self.tradeSession.refreshQuote(self.tradeSession.orderInfo.symbol, ^(double lastPrice, double priceChangeDollar, double priceChangePercentage, NSString * quoteUpdateTime){

                //return to main thread as this triggers a UI change
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.tradeSession.lastPrice = lastPrice;
                    self.tradeSession.priceChangeDollar = [NSNumber numberWithDouble:priceChangeDollar];
                    self.tradeSession.priceChangePercentage = [NSNumber numberWithDouble:priceChangePercentage];
                    [self updatePrice];
                });
            });
        });
    }
    else if(self.tradeSession.refreshLastPrice != nil) {
        //perform network request (most likely) off the main thread
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0),  ^(void){
            self.tradeSession.refreshLastPrice(self.tradeSession.orderInfo.symbol, ^(double price){
                //return to main thread as this triggers a UI change
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    self.tradeSession.lastPrice = price;
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
    
    if (!self.tradeSession.orderInfo.quantity) {
        appendedString = [NSString stringWithFormat:@"%ld", (long)key];
    } else {
        currentQuantityString = [NSString stringWithFormat:@"%i", self.tradeSession.orderInfo.quantity];
        newQuantityString = [NSString stringWithFormat:@"%ld", (long)key];
        
        if (key == 11) { // backspace
            appendedString = [currentQuantityString substringToIndex:[currentQuantityString length] - 1];
        } else {
            appendedString = [NSString stringWithFormat:@"%@%@", currentQuantityString, newQuantityString];
        }
    }
    
    self.tradeSession.orderInfo.quantity = [appendedString intValue];
    sharesInput.text = [helper formatIntegerToReadablePrice:appendedString];
    
    [self checkIfReadyToTrade];
}

- (IBAction)orderActionPressed:(id)sender {
    [self.view endEditing:YES];

    orderActionButton.layer.borderColor = helper.activeButtonColor.CGColor;

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
    [self performSegueWithIdentifier:@"CalculatorToOrderTypeSelection" sender:self];
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
        self.tradeSession.orderInfo.quantity = (int)[[sharesInput text] integerValue];

        if([self.tradeSession.orderInfo.price.type isEqualToString:@"stopLimit"]) {
            self.tradeSession.orderInfo.price.limitPrice = [NSNumber numberWithDouble:[helper numberFromPriceString:limitPriceInput.text]];
            self.tradeSession.orderInfo.price.stopPrice = [NSNumber numberWithDouble:[helper numberFromPriceString:stopPriceInput.text]];
        } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"stopMarket"]) {
            self.tradeSession.orderInfo.price.stopPrice = [NSNumber numberWithDouble:[helper numberFromPriceString:limitPriceInput.text]];
        } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"limit"]) {
            self.tradeSession.orderInfo.price.limitPrice = [NSNumber numberWithDouble:[helper numberFromPriceString:limitPriceInput.text]];
        }

        [helper styleLoadingButton:previewOrderButton];
        [self sendLoginReviewRequest];
    }
}

- (IBAction)cancelPressed:(id)sender {
    [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
}

- (IBAction)portfolioLinkPressed:(id)sender {
    [self performSegueWithIdentifier:@"CalculatorToPortfolio" sender:self];
}

- (IBAction)editAccountsPressed:(id)sender {
    [self performSegueWithIdentifier:@"advCalculatorToBrokerSelectDetail" sender:self];
}


#pragma mark - Picker View

-(UIView *) createPickerView: (NSString *) title {
    UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 270, 20)];
    [titleLabel setTextColor:[UIColor blackColor]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setFont: [UIFont boldSystemFontOfSize:16.0f]];
    [titleLabel setNumberOfLines:0];
    [titleLabel setText: title];
    [contentView addSubview:titleLabel];
    
    UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, 20, 270, 130)];
    currentPicker = picker;
    
    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [contentView addSubview:picker];
    
    [contentView setNeedsDisplay];
    return contentView;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return pickerTitles.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return pickerTitles[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    currentSelection = pickerValues[row];
}



#pragma mark - login

- (void) sendLoginReviewRequest {
    [[self tradeSession] asyncAuthenticateAndReviewWithCompletionBlock:^(TradeItResult* result){
        [self loginReviewRequestRecieved: result];
    }];
}

- (void) loginReviewRequestRecieved: (TradeItResult *) result {
    self.lastResult = result;

    if ([result isKindOfClass:[TradeItStockOrEtfTradeReviewResult class]]){
        //REVIEW
        self.tradeSession.resultContainer.status = USER_CANCELED;
        self.tradeSession.resultContainer.reviewResponse = (TradeItStockOrEtfTradeReviewResult *) result;
        
        [self setReviewResult:(TradeItStockOrEtfTradeReviewResult *) result];
         [self performSegueWithIdentifier: @"CalculatorToReview" sender: self];
    }
    else if ([result isKindOfClass:[TradeItSecurityQuestionResult class]]){
        self.tradeSession.resultContainer.status = USER_CANCELED_SECURITY;
        
        //SECURITY QUESTION
        TradeItSecurityQuestionResult *securityQuestionResult = (TradeItSecurityQuestionResult *) result;
        
        if (securityQuestionResult.securityQuestionOptions != nil && securityQuestionResult.securityQuestionOptions.count > 0 ){
            //MULTI
            if(![UIAlertController class]) {
                 [self showOldMultiSelect:securityQuestionResult];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Verify Identity"
                                                                                message:securityQuestionResult.securityQuestion
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                
                for(NSString * title in securityQuestionResult.securityQuestionOptions){
                    UIAlertAction * option = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction * action) {
                                                                        [[self tradeSession] asyncAnswerSecurityQuestion:title andCompletionBlock:^(TradeItResult *result) {
                                                                            // [self loginReviewRequestRecieved:result];
                                                                        }];
                                                                    }];
                    [alert addAction:option];
                }
                
                UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          // [self dismissViewControllerAnimated:YES completion:nil];
                                                                      }];
                [alert addAction:cancelAction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                     [self presentViewController:alert animated:YES completion:nil];
                }) ;
            }
        } else if (securityQuestionResult.securityQuestion != nil){
            //SINGLE
            if(![UIAlertController class]) {
                 [self showOldSecQuestion: securityQuestionResult.securityQuestion];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Security Question"
                                                                                message:securityQuestionResult.securityQuestion
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                           [self dismissViewControllerAnimated:YES completion:nil];
                                                                      }];
                UIAlertAction * submitAction = [UIAlertAction actionWithTitle:@"SUBMIT" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          [[self tradeSession] asyncAnswerSecurityQuestion: [[alert textFields][0] text] andCompletionBlock:^(TradeItResult *result) { [self loginReviewRequestRecieved:result]; }];
                                                                      }];
                
                [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {}];
                [alert addAction:cancelAction];
                [alert addAction:submitAction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                     [self presentViewController:alert animated:YES completion:nil];
                });
            }
        }
    } else if([result isKindOfClass:[TradeItMultipleAccountResult class]]){
        //ACCOUNT SELECT
        TradeItMultipleAccountResult * multiAccountResult = (TradeItMultipleAccountResult* ) result;
        
        if(![UIAlertController class]) {
            [self showOldAcctSelect: multiAccountResult];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Account"
                                                                            message:nil
                                                                     preferredStyle:UIAlertControllerStyleActionSheet];
            
            void (^handler)(NSDictionary * account) = ^(NSDictionary * account){
                [[self tradeSession] asyncSelectAccount:account andCompletionBlock:^(TradeItResult *result) {
                    [self loginReviewRequestRecieved:result];
                }];
            };

            for (NSDictionary * account in multiAccountResult.accountList) {
                NSString * title = [account objectForKey:@"name"];
                UIAlertAction * acct = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  handler(account);
                                                              }];
                [alert addAction:acct];
            }
            
            UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            [alert addAction:cancel];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }
    else if([result isKindOfClass:[TradeItErrorResult class]]){
        NSString * errorMessage = @"Could Not Complete Your Order";
        TradeItErrorResult * error = (TradeItErrorResult *) result;
        
        if(error.errorFields.count > 0) {
            NSString * errorField = (NSString *) error.errorFields[0];
            if([errorField isEqualToString:@"authenticationInfo"]) {
                errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
                
                self.tradeSession.resultContainer.status = AUTHENTICATION_ERROR;
                self.tradeSession.resultContainer.errorResponse = error;
            } else {
                errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
            }
        }
        
        if(![UIAlertController class]) {
            [self showOldErrorAlert:@"Could Not Complete Order" withMessage:errorMessage];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                            message:errorMessage
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       [self dismissViewControllerAnimated:YES completion:nil];
                                                                   }];
            [alert addAction:defaultAction];
                        [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        if(![UIAlertController class]) {
            [self showOldErrorAlert:@"Could Not Complete Order" withMessage:@"TradeIt is temporarily unavailable. Please try again in a few minutes."];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                            message:@"TradeIt is temporarily unavailable. Please try again in a few minutes."
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       [self dismissViewControllerAnimated:YES completion:nil];
                                                                   }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}



#pragma mark - iOS7 Fallbacks

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) showOldAcctSelect: (TradeItMultipleAccountResult *) multiAccountResult {
    questionOptions = multiAccountResult.accountList;
    currentAccount = questionOptions[0];
    
    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 0) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [[self tradeSession] asyncSelectAccount:currentAccount andCompletionBlock:^(TradeItResult *result) {
                [self loginReviewRequestRecieved:result];
            }];
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) showOldSecQuestion:(NSString *) question {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:@"Security Question" message:question delegate: self cancelButtonTitle:@"CANCEL" otherButtonTitles: @"SUBMIT", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) showOldMultiSelect:(TradeItSecurityQuestionResult *) securityQuestionResult {
    questionOptions = securityQuestionResult.securityQuestionOptions;
    currentSelection = questionOptions[0];
    
    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SUBMIT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 0) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [[self tradeSession] asyncAnswerSecurityQuestion:currentSelection andCompletionBlock:^(TradeItResult *result) {
                [self loginReviewRequestRecieved:result];
            }];
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) showOldOrderAction {
    pickerTitles = @[@"Buy",@"Sell",@"Buy to Cover",@"Sell Short"];
    pickerValues = @[@"buy",@"sell",@"buyToCover",@"sellShort"];
    currentSelection = self.tradeSession.orderInfo.action;
    
    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Order Action"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 1) {
            [self changeOrderAction: currentSelection];
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
        
        if([self.tradeSession.orderInfo.action isEqualToString:@"sellShort"]){
            [currentPicker selectRow:3 inComponent:0 animated:NO];
        } else if([self.tradeSession.orderInfo.action isEqualToString:@"buyToCover"]){
            [currentPicker selectRow:2 inComponent:0 animated:NO];
        } else if([self.tradeSession.orderInfo.action isEqualToString:@"sell"]){
            [currentPicker selectRow:1 inComponent:0 animated:NO];
        }
    });
}

-(void) showOldOrderExp {
    pickerTitles = @[@"Good For The Day",@"Good Until Canceled"];
    pickerValues = @[@"day",@"gtc"];
    currentSelection = self.tradeSession.orderInfo.expiration;

    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Order Action"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 1) {
            [self changeOrderExpiration: currentSelection];
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
        
        if([self.tradeSession.orderInfo.expiration isEqualToString:@"gtc"]) {
            [currentPicker selectRow:1 inComponent:0 animated:NO];
        }
    });
}

- (UIView *)createPickerView {
    if([self.lastResult isKindOfClass:[TradeItSecurityQuestionResult class]]) {
        return [self createSecurityPickerView];
    } else {
        return [self createAccountPickerView];
    }
}

- (UIView *)createAccountPickerView {
    UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 270, 50)];
    [title setTextColor:[UIColor blackColor]];
    [title setTextAlignment:NSTextAlignmentCenter];
    [title setFont: [UIFont boldSystemFontOfSize:16.0f]];
    [title setNumberOfLines:0];
    [title setText: @"Select the account\ryou want to trade in"];
    [contentView addSubview:title];
    
    UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, 50, 270, 130)];
    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [picker setTag: 502];
    [contentView addSubview:picker];
    
    [contentView setNeedsDisplay];
    return contentView;
}

- (UIView *)createSecurityPickerView {
    UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    TradeItSecurityQuestionResult * currentResult = (TradeItSecurityQuestionResult *) self.lastResult;
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 270, 20)];
    [title setTextColor:[UIColor blackColor]];
    [title setTextAlignment:NSTextAlignmentCenter];
    [title setFont: [UIFont boldSystemFontOfSize:16.0f]];
    [title setText: @"Verify Identity"];
    [contentView addSubview:title];
    
    UILabel * question = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, 270, 150)];
    [question setTextColor:[UIColor blackColor]];
    [question setTextAlignment:NSTextAlignmentCenter];
    [question setFont:[UIFont systemFontOfSize:12]];
    [question setNumberOfLines:0];
    [question setText: currentResult.securityQuestion];
    
    //resize to fit text
    CGSize requiredSize = [question sizeThatFits:CGSizeMake(270, 150)];
    CGRect questionFrame = question.frame;
    CGFloat questionHeight = questionFrame.size.height = requiredSize.height;
    question.frame = questionFrame;
    
    [contentView addSubview:question];
    
    //If the question is more than two lines, stretch it!
    if(questionHeight > 30) {
        CGRect contentFrame = contentView.frame;
        contentFrame.size.height = 250;
        contentView.frame = contentFrame;
    }
    
    UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, (20 + questionHeight), 270, (200 - 35 - questionHeight))];
    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [picker setTag: 501];
    [contentView addSubview:picker];
    
    [contentView setNeedsDisplay];
    
    return contentView;
}

@end
