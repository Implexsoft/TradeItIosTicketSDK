//
//  AdvCalculatorViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/29/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKAdvCalculatorViewController.h"
#import "TTSDKHelper.h"

@interface TTSDKAdvCalculatorViewController () {
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

    NSLayoutConstraint * zeroHeightConstraint;
    NSLayoutConstraint * fullHeightConstraint;

    BOOL readyToTrade;

    NSString * currentFocus;

    NSArray * pickerTitles;
    NSArray * pickerValues;
    NSString * currentSelection;
    UIPickerView * currentPicker;
    UIView * keypad;

    TTSDKHelper * helper;
}

@end

@implementation TTSDKAdvCalculatorViewController


/*** Delegate Methods ***/

- (void)viewDidLoad {
    self.advMode = YES;
    [super viewDidLoad];

    helper = [TTSDKHelper sharedHelper];

    readyToTrade = YES;

    [self initConstraints];
    [self uiTweaks];

    [self changeOrderAction:self.tradeSession.orderInfo.action];
    [self changeOrderType:self.tradeSession.orderInfo.price.type];
    [self changeOrderExpiration:self.tradeSession.orderInfo.expiration];

    [[self navigationItem] setTitle: [TTSDKTradeItTicket getBrokerDisplayString:self.tradeSession.broker]];

    [companyNameLabel setText:self.tradeSession.orderInfo.symbol];
    [self updatePrice];
    [self checkIfReadyToTrade];

    if(self.tradeSession.orderInfo.quantity > 0) {
        [sharesInput setText:[NSString stringWithFormat:@"%i", self.tradeSession.orderInfo.quantity]];
    }

    [sharesInput becomeFirstResponder];
    [self refreshPressed:self];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(refreshPressed:)];
    [companyDetails addGestureRecognizer:tap];

    [self initKeypad];

    [self changeOrderFocus:@"shares"];
}

-(void) viewDidAppear:(BOOL)animated {
    self.advMode = YES;
    [super viewDidAppear:animated];

    [self changeOrderAction:self.tradeSession.orderInfo.action];
    [self changeOrderType:self.tradeSession.orderInfo.price.type];
    [self changeOrderExpiration:self.tradeSession.orderInfo.expiration];

    [self setBroker];

    [[self navigationItem] setTitle: [TTSDKTradeItTicket getBrokerDisplayString:self.tradeSession.broker]];
}



#pragma mark - Initialization

- (void)initKeypad {
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
    NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];
    NSArray * keypadArray = [resourceBundle loadNibNamed:@"TTSDKcalc" owner:self options:nil];
    keypad = [keypadArray firstObject];
    CGRect frame = CGRectMake(0, 0, keypadContainer.frame.size.width, keypadContainer.frame.size.height);
    keypad.frame = frame;

    [keypadContainer addSubview:keypad];
    keypad.userInteractionEnabled = YES;
    NSArray * subviews = keypad.subviews;

    for (int i = 0; i < [subviews count]; i++) {
        UIButton *button = [subviews objectAtIndex:i];
        [button addTarget:self action:@selector(keypadPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
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

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL isShares = textField == sharesInput;
    BOOL isLimit = textField == limitPriceInput;
    BOOL isStop = textField == stopPriceInput;

    if (isShares) {
        [self sharesInputPressed];
    } else if (isLimit) {
        [self limitInputPressed];
    } else if (isStop) {
        [self stopInputPressed];
    }

    return NO;
}

-(void) sharesInputPressed {
    [self changeOrderFocus:@"shares"];
}

-(void) limitInputPressed {
    [self changeOrderFocus:@"limitPrice"];
}

-(void) stopInputPressed {
    [self changeOrderFocus:@"stopPrice"];
}

-(void) uiTweaks { // things that can't be done in Storyboard
    [self applyBorder:(UIView *)sharesInput];
    [self applyBorder:(UIView *)orderActionButton];

    [previewOrderButton.layer setCornerRadius:22.0f];
    previewOrderButton.clipsToBounds = YES;
    orderActionButton.layer.borderColor = [UIColor colorWithRed:0.0f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0].CGColor;
}

-(void) applyBorder: (UIView *) item {
    item.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    item.layer.borderWidth = 1;
    item.layer.cornerRadius = item.frame.size.height / 2;
}



#pragma mark - Order State

-(void) checkIfReadyToTrade {
    [self updateEstimatedCost];

    BOOL readyNow = NO;
    NSInteger shares = [sharesInput.text integerValue];

    double limitPrice = [limitPriceInput.text doubleValue];
    double stopPrice = [stopPriceInput.text doubleValue];

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

    if(readyNow != readyToTrade) {
        if(readyNow) {
            [previewOrderButton setBackgroundColor:helper.activeButtonColor];
            [previewOrderButton.layer addSublayer:[helper activeGradientWithBounds:previewOrderButton.layer.bounds]];
        } else {
            [previewOrderButton setBackgroundColor:[UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:200.0f/255.0f alpha:1.0f]];
        }
    }

    readyToTrade = readyNow;
}

-(void) changeOrderFocus: (NSString *)focus {
    if ([focus isEqualToString:@"limitPrice"]) {
        if (self.tradeSession.orderInfo.price.limitPrice && ![self.tradeSession.orderInfo.price.limitPrice intValue] == 0) {
            [helper styleFocusedInput:limitPriceInput withPlaceholder:[NSString stringWithFormat:@"%@", self.tradeSession.orderInfo.price.limitPrice]];
        } else {
            [helper styleFocusedInput:limitPriceInput withPlaceholder:@"Limit Price"];
        }
    } else {
        if (self.tradeSession.orderInfo.price.limitPrice && ![self.tradeSession.orderInfo.price.limitPrice intValue] == 0) {
            [helper styleUnfocusedInput:limitPriceInput withPlaceholder:[NSString stringWithFormat:@"%@", self.tradeSession.orderInfo.price.limitPrice]];
        } else {
            [helper styleUnfocusedInput:limitPriceInput withPlaceholder:@"Limit Price"];
        }
    }
    if ([focus isEqualToString:@"stopPrice"]) {
        if (self.tradeSession.orderInfo.price.stopPrice) {
            [helper styleFocusedInput:stopPriceInput withPlaceholder:[NSString stringWithFormat:@"%@", self.tradeSession.orderInfo.price.stopPrice]];
        } else {
            [helper styleFocusedInput:stopPriceInput withPlaceholder:@"Stop Price"];
        }
    } else {
        if (self.tradeSession.orderInfo.price.stopPrice) {
            [helper styleUnfocusedInput:stopPriceInput withPlaceholder:[NSString stringWithFormat:@"%@", self.tradeSession.orderInfo.price.stopPrice]];
        } else {
            [helper styleUnfocusedInput:stopPriceInput withPlaceholder:@"Stop Price"];
        }
    }
    if ([focus isEqualToString:@"shares"]) {
        [helper styleBorderedFocusInput:sharesInput];
    } else {
        [helper styleBorderedUnfocusInput:sharesInput];
    }

    currentFocus = focus;
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

    [attString addAttribute:NSForegroundColorAttributeName
                      value:[UIColor colorWithRed:169.0f/255.0f green:169.0f/255.0f blue:169.0f/255.0f alpha:1.0f]
                      range:NSMakeRange(0, 15)];

    [attString addAttribute:NSForegroundColorAttributeName
                      value:[UIColor blackColor]
                      range:NSMakeRange(16, [attString length] - 16)];

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
            NSAttributedString * attString = [self getColoredString:changeDollar withFormat:NSNumberFormatterCurrencyStyle];

            [finalString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            [finalString appendAttributedString:(NSAttributedString *) attString];
        }
    }

    if(changePercentage != nil) {
        if([changePercentage doubleValue] == 0) {
            [finalString appendAttributedString:[[NSAttributedString alloc] initWithString:@" $0.00"]];
        } else {
            NSAttributedString * attString = [self getColoredString:changePercentage withFormat:NSNumberFormatterDecimalStyle];

            [finalString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            [finalString appendAttributedString:(NSAttributedString *) attString];
        }
    }

    performanceLabel.attributedText = (NSAttributedString *) finalString;
}

-(void) changeOrderAction: (NSString *) action {
    [orderActionButton setTitle:[TTSDKTradeItTicket splitCamelCase:action] forState:UIControlStateNormal];
    self.tradeSession.orderInfo.action = action;
}

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

-(void) sharesChangedByProxy:(NSInteger) key {
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

-(void) limitPriceChangedByProxy:(NSInteger) key {
    NSString *limitPriceString;
    if (self.tradeSession.orderInfo.price.limitPrice) {
        limitPriceString = [NSString stringWithFormat:@"%@", self.tradeSession.orderInfo.price.limitPrice];
    } else {
        limitPriceString = @"0";
    }

    NSString * currentLimitString = [NSString stringWithFormat:@"%@", limitPriceString];
    NSString * newLimitString;

    if (key == 10 && [currentLimitString rangeOfString:@"."].location != NSNotFound) { // don't allow more than one decimal point
        return;
    }

    if (key == 11) { // backspace
        newLimitString = [currentLimitString substringToIndex:[currentLimitString length] - 1];
    } else if (key == 10) { // decimal point
        newLimitString = [NSString stringWithFormat:@"%@.", currentLimitString];
    } else {
        newLimitString = [NSString stringWithFormat:@"%@%li", currentLimitString, (long)key];
    }

    self.tradeSession.orderInfo.price.limitPrice = [NSNumber numberWithDouble:[newLimitString doubleValue]];

    limitPriceInput.text = [NSString stringWithFormat:@"%@", newLimitString];

    [self checkIfReadyToTrade];
}

-(void) stopPriceChangedByProxy:(NSInteger) key {
    NSString * currentStopString = [NSString stringWithFormat:@"%@", self.tradeSession.orderInfo.price.stopPrice];
    NSString * newStopString;

    if (key == 10 && [currentStopString rangeOfString:@"."].location != NSNotFound) { // don't allow more than one decimal point
        return;
    }

    if (key == 11) { // backspace
        newStopString = [currentStopString substringToIndex:[currentStopString length] - 1];
    } else if (key == 10) { // decimal point
        newStopString = [NSString stringWithFormat:@"%@.", currentStopString];
    } else {
        newStopString = [NSString stringWithFormat:@"%@%li", currentStopString, (long)key];
    }

    self.tradeSession.orderInfo.price.stopPrice = [NSNumber numberWithDouble:[newStopString doubleValue]];

    stopPriceInput.text = [NSString stringWithFormat:@"%@", newStopString];

    [self checkIfReadyToTrade];
}

-(void) setToMarketOrder {
    self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initMarket];
    [self changeOrderExpiration:@"day"];
    [self hideLimitContainer];
}

-(void) setToLimitOrder {
    [stopPriceInput setHidden:YES];
    [limitPriceInput setHidden:NO];
    [limitPriceInput setPlaceholder:@"Limit Price"];

    self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initLimit:0.0];

    [self showLimitContainer];
}

-(void) setToStopMarketOrder {
    [stopPriceInput setHidden:YES];
    [limitPriceInput setHidden:NO];
    [limitPriceInput setPlaceholder:@"Stop Price"];

    self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopMarket:0.0];

    [self showLimitContainer];
}

-(void) setToStopLimitOrder {
    [stopPriceInput setHidden: NO];
    [limitPriceInput setHidden:NO];
    [limitPriceInput setPlaceholder:@"Limit Price"];

    self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopLimit:0.0 :0.0];

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

-(NSAttributedString *) getColoredString: (NSNumber *) number withFormat: (int) style {
    UIColor * positiveColor = [UIColor colorWithRed:58.0f/255.0f green:153.0f/255.0f blue:69.0f/255.0f alpha:1.0f];
    UIColor * negativeColor = [UIColor colorWithRed:197.0f/255.0f green:81.0f/255.0f blue:75.0f/255.0f alpha:1.0f];
    
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:style];
    [formatter setLocale:US];
    
    NSMutableAttributedString * attString;
    if([number doubleValue] > 0) {
        attString = [[NSMutableAttributedString alloc] initWithString:@"\u25B2"];
    } else {
        attString = [[NSMutableAttributedString alloc] initWithString:@"\u25BC"];
    }
    
    double absValue = fabs([number doubleValue]);
    NSString * asString = [formatter stringFromNumber:[NSNumber numberWithDouble:absValue]];
    [attString appendAttributedString:[[NSAttributedString alloc] initWithString:asString]];
    
    if(style == NSNumberFormatterDecimalStyle) {
        [attString appendAttributedString:[[NSAttributedString alloc] initWithString:@"%"]];
    }
    
    if([number doubleValue] > 0) {
        [attString addAttribute:NSForegroundColorAttributeName
                          value:positiveColor
                          range:NSMakeRange(0, [attString length])];
    } else {
        [attString addAttribute:NSForegroundColorAttributeName
                          value:negativeColor
                          range:NSMakeRange(0, [attString length])];
    }
    
    return (NSAttributedString *) attString;
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    if([segue.identifier isEqualToString:@"advCalculatorToLoading"]){
        [[segue destinationViewController] setActionToPerform: @"sendLoginReviewRequest"];
    } else if([segue.identifier isEqualToString:@"advCalculatorToBrokerSelectDetail"]) {
        [[segue destinationViewController] setCancelToParent: YES];
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



#pragma mark - Events

- (IBAction)sharesInputPressed:(id)sender {
    [self changeOrderFocus:@"shares"];
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

    BOOL focusIsShares = [currentFocus isEqualToString:@"shares"];
    BOOL focusIsLimitPrice = [currentFocus isEqualToString:@"limitPrice"];
    BOOL focusIsStopPrice = [currentFocus isEqualToString:@"stopPrice"];

    if (focusIsShares) {
        [self sharesChangedByProxy:key];
    } else if (focusIsLimitPrice) {
        [self limitPriceChangedByProxy:key];
    } else if (focusIsStopPrice) {
        [self stopPriceChangedByProxy:key];
    }
}

- (IBAction)orderActionPressed:(id)sender {
    [self.view endEditing:YES];

    if(![UIAlertController class]) {
        [self showOldOrderAction];
        return;
    }

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Order Action"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction* buyAction = [UIAlertAction actionWithTitle:@"Buy" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) { [self changeOrderAction:@"buy"]; }];
    UIAlertAction* sellAction = [UIAlertAction actionWithTitle:@"Sell" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) { [self changeOrderAction:@"sell"]; }];
    UIAlertAction* sellShortAction = [UIAlertAction actionWithTitle:@"Sell Short" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) { [self changeOrderAction:@"sellShort"]; }];
    UIAlertAction* buyToCoverAction = [UIAlertAction actionWithTitle:@"Buy to Cover" style:UIAlertActionStyleDefault
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

    if(![UIAlertController class]) {
        [self showOldOrderType];
        return;
    }

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Order Type"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction* marketAction = [UIAlertAction actionWithTitle:@"Market" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) { [self changeOrderType:@"market"]; }];
    UIAlertAction* limitAction = [UIAlertAction actionWithTitle:@"Limit" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) { [self changeOrderType:@"limit"]; }];
    UIAlertAction* stopMarketAction = [UIAlertAction actionWithTitle:@"Stop Market" style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) { [self changeOrderType:@"stopMarket"]; }];
    UIAlertAction* stopLimitAction = [UIAlertAction actionWithTitle:@"Stop Limit" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) { [self changeOrderType:@"stopLimit"]; }];
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];

    [alert addAction:marketAction];
    [alert addAction:limitAction];
    [alert addAction:stopMarketAction];
    [alert addAction:stopLimitAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)orderExpirationPressed:(id)sender {
    [self.view endEditing:YES];

    if(![UIAlertController class]) {
        [self showOldOrderExp];
        return;
    }

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Order Expiration"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction* dayAction = [UIAlertAction actionWithTitle:@"Good For The Day" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) { [self changeOrderExpiration:@"day"]; }];
    UIAlertAction* gtcAction = [UIAlertAction actionWithTitle:@"Good Until Canceled" style:UIAlertActionStyleDefault
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
            self.tradeSession.orderInfo.price.limitPrice = [NSNumber numberWithDouble:[[limitPriceInput text] doubleValue]];
            self.tradeSession.orderInfo.price.stopPrice = [NSNumber numberWithDouble:[[stopPriceInput text] doubleValue]];
        } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"stopMarket"]) {
            self.tradeSession.orderInfo.price.stopPrice = [NSNumber numberWithDouble:[[limitPriceInput text] doubleValue]];
        } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"limit"]) {
            self.tradeSession.orderInfo.price.limitPrice = [NSNumber numberWithDouble:[[limitPriceInput text] doubleValue]];
        }

        [self performSegueWithIdentifier:@"advCalculatorToLoading" sender:self];
    }
}

- (IBAction)cancelPressed:(id)sender {
    [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
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



#pragma mark - iOS7 Fallbacks

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];

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

-(void) showOldOrderType {
    pickerTitles = @[@"Market",@"Limit",@"Stop Market",@"Stop Limit"];
    pickerValues = @[@"market",@"limit",@"stopMarket",@"stopLimit"];
    currentSelection = self.tradeSession.orderInfo.price.type;

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

        if([self.tradeSession.orderInfo.price.type isEqualToString:@"stopLimit"]){
            [currentPicker selectRow:3 inComponent:0 animated:NO];
        } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"stopMarket"]) {
            [currentPicker selectRow:2 inComponent:0 animated:NO];
        } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"limit"]) {
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



@end
