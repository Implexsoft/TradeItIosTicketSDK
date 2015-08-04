//
//  AdvCalculatorViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/29/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "AdvCalculatorViewController.h"

@interface AdvCalculatorViewController () {
    
    __weak IBOutlet UILabel *companyNameLabel;
    __weak IBOutlet UILabel *priceAndPerformanceLabel;
    
    __weak IBOutlet UITextField *sharesInput;
    __weak IBOutlet UITextField *symbolBox;
    
    __weak IBOutlet UIButton *orderActionButton;
    
    __weak IBOutlet UIButton *orderTypeButton;
    
    __weak IBOutlet UIView *limitPricesView;
    __weak IBOutlet UITextField *leftPriceInput;
    __weak IBOutlet UITextField *rightPriceInput;
    
    __weak IBOutlet UIButton *orderExpirationButton;
    
    __weak IBOutlet UILabel *estimatedCostLabel;
    
    __weak IBOutlet UIButton *previewOrderButton;
    
    NSLayoutConstraint * zeroHeightConstraint;
    NSLayoutConstraint * fullHeightConstraint;
    
    BOOL readyToTrade;
}

@end

@implementation AdvCalculatorViewController

- (void)viewDidLoad {
    self.advMode = YES;
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    readyToTrade = YES;
    
    [self initConstraints];
    [self uiTweaks];
    
    [self changeOrderAction:self.tradeSession.orderInfo.action];
    [self changeOrderType:self.tradeSession.orderInfo.price.type];
    [self changeOrderExpiration:self.tradeSession.orderInfo.expiration];
    
    [[self navigationItem] setTitle: [TradeItTicket getBrokerDisplayString:self.tradeSession.broker]];
    
    [symbolBox setText:self.tradeSession.orderInfo.symbol];
    
    NSString * companyNameString;
    if(self.tradeSession.companyName != nil) {
        companyNameString = [NSString stringWithFormat:@"%@ (%@)", self.tradeSession.companyName, self.tradeSession.orderInfo.symbol];
    } else {
        companyNameString = self.tradeSession.orderInfo.symbol;
    }
    
    [companyNameLabel setText:companyNameString];
    [self updatePrice];
    [self checkIfReadyToTrade];
    
    if(self.tradeSession.orderInfo.quantity > 0) {
        [sharesInput setText:[NSString stringWithFormat:@"%i", self.tradeSession.orderInfo.quantity]];
    }
    
    [sharesInput addTarget:self action:@selector(sharesInputChanged) forControlEvents:UIControlEventEditingChanged];
    [leftPriceInput addTarget:self action:@selector(leftInputChanged) forControlEvents:UIControlEventEditingChanged];
    [rightPriceInput addTarget:self action:@selector(rightInputChanged) forControlEvents:UIControlEventEditingChanged];
}

-(void) viewDidAppear:(BOOL)animated {
    self.advMode = YES;
    [super viewDidAppear:animated];
    
    [self changeOrderAction:self.tradeSession.orderInfo.action];
    [self changeOrderType:self.tradeSession.orderInfo.price.type];
    [self changeOrderExpiration:self.tradeSession.orderInfo.expiration];
    
    [self setBroker];
    
    [[self navigationItem] setTitle: [TradeItTicket getBrokerDisplayString:self.tradeSession.broker]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) checkIfReadyToTrade {
    [self updateEstimatedCost];
    
    BOOL readyNow = NO;
    NSInteger shares = [sharesInput.text integerValue];
    
    double leftPrice = [leftPriceInput.text doubleValue];
    double rightPrice = [rightPriceInput.text doubleValue];
    
    if(shares < 1) {
        readyNow = NO;
    } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"stopLimitOrder"]) {
        if(leftPrice > 0 && rightPrice > 0) {
            readyNow = YES;
        }
    } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"market"]) {
        readyNow = YES;
    } else {
        if(leftPrice > 0) {
            readyNow = YES;
        }
    }
    
    if(readyNow != readyToTrade) {
        if(readyNow) {
            [previewOrderButton setBackgroundColor:[UIColor colorWithRed:20.0f/255.0f green:63.0f/255.0f blue:119.0f/255.0f alpha:1.0f]];
        } else {
            [previewOrderButton setBackgroundColor:[UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:200.0f/255.0f alpha:1.0f]];
        }
    }
    
    readyToTrade = readyNow;
}

-(void) updateEstimatedCost {
    NSInteger shares = self.tradeSession.orderInfo.quantity;
    double price = self.tradeSession.lastPrice;
    
    if([self.tradeSession.orderInfo.price.type isEqualToString:@"stopMarket"]){
        price = [self.tradeSession.orderInfo.price.stopPrice doubleValue];
    } else if([self.tradeSession.orderInfo.price.type containsString:@"imit"]) {
        price = [self.tradeSession.orderInfo.price.limitPrice doubleValue];
    }
    
    double estimatedCost = shares * price;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSString * equalitySign = [self.tradeSession.orderInfo.price.type containsString:@"arket"] ? @"\u2248" : @"=";
    NSString * formattedString = [NSString stringWithFormat:@"%@   %@ %@", @"Estimated Total", equalitySign, [formatter stringFromNumber: [NSNumber numberWithDouble:estimatedCost]]];
    
    NSMutableAttributedString * attString = [[NSMutableAttributedString alloc] initWithString:formattedString];
    
    [attString addAttribute:NSForegroundColorAttributeName
                      value:[UIColor colorWithRed:169.0f/255.0f green:169.0f/255.0f blue:169.0f/255.0f alpha:1.0f]
                      range:NSMakeRange(0, 15)];
    
    [attString addAttribute:NSForegroundColorAttributeName
                      value:[UIColor blackColor]
                      range:NSMakeRange(16, [attString length] - 16)];
    
    [estimatedCostLabel setAttributedText:attString];
}

#pragma mark - UI Changes

//things that can't be done in IB
-(void) uiTweaks {
    [self applyBorder:(UIView *)sharesInput];
    [self applyBorder:(UIView *)symbolBox];
    [self applyBorder:(UIView *)orderActionButton];
    [self applyBorder:(UIView *)orderTypeButton];
    [self applyBorder:(UIView *)leftPriceInput];
    [self applyBorder:(UIView *)rightPriceInput];
    [self applyBorder:(UIView *)orderExpirationButton];
    
    symbolBox.enabled = NO;
    
    [previewOrderButton.layer setCornerRadius:5.0f];
}

-(void) applyBorder: (UIView *) item {
    item.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    item.layer.borderWidth = 1;
}

-(void) updatePrice {
    double lastPrice = self.tradeSession.lastPrice;
    NSNumber * changeDollar = self.tradeSession.priceChangeDollar;
    NSNumber * changePercentage = self.tradeSession.priceChangePercentage;
    
    NSMutableAttributedString * finalString;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSString * lastPriceString = [formatter stringFromNumber:[NSNumber numberWithDouble:lastPrice]];
    finalString = [[NSMutableAttributedString alloc] initWithString:lastPriceString];
    
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
    
    priceAndPerformanceLabel.attributedText = (NSAttributedString *) finalString;
}

-(NSAttributedString *) getColoredString: (NSNumber *) number withFormat: (int) style {
    UIColor * positiveColor = [UIColor colorWithRed:58.0f/255.0f green:153.0f/255.0f blue:69.0f/255.0f alpha:1.0f];
    UIColor * negativeColor = [UIColor colorWithRed:197.0f/255.0f green:81.0f/255.0f blue:75.0f/255.0f alpha:1.0f];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:style];
    
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

#pragma mark - Change Order

-(void) changeOrderAction: (NSString *) action {
    [orderActionButton setTitle:[TradeItTicket splitCamelCase:action] forState:UIControlStateNormal];
    self.tradeSession.orderInfo.action = action;
}

-(void) changeOrderExpiration: (NSString *) exp {
    if([self.tradeSession.orderInfo.price.type isEqualToString:@"market"] && [exp isEqualToString:@"gtc"]) {
        self.tradeSession.orderInfo.expiration = @"day";
        
        UIAlertView * alert;
        alert = [[UIAlertView alloc] initWithTitle:@"Invalid Expiration" message:@"Market orders are Good For The Day only." delegate: self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        
        [alert show];
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
    [orderTypeButton setTitle:[TradeItTicket splitCamelCase:type] forState:UIControlStateNormal];
    
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
}

-(void) setToLimitOrder {
    [rightPriceInput setHidden:YES];
    [leftPriceInput setHidden:NO];
    [leftPriceInput setPlaceholder:@"Limit Price"];
    
    self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initLimit:0.0];
    
    [self showLimitContainer];
}

-(void) setToStopMarketOrder {
    [rightPriceInput setHidden:YES];
    [leftPriceInput setHidden:NO];
    [leftPriceInput setPlaceholder:@"Stop Price"];
    
    self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopMarket:0.0];
    
    [self showLimitContainer];
}

-(void) setToStopLimitOrder {
    [rightPriceInput setHidden: NO];
    [leftPriceInput setHidden:NO];
    [leftPriceInput setPlaceholder:@"Limit Price"];
    
    self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopLimit:0.0 :0.0];
    
    [self showLimitContainer];
}

-(void) hideLimitContainer {
    [self.view removeConstraint:fullHeightConstraint];
    [self.view addConstraint:zeroHeightConstraint];
    [leftPriceInput setHidden:YES];
    [rightPriceInput setHidden:YES];
}

-(void) showLimitContainer {
    [self.view removeConstraint:zeroHeightConstraint];
    [self.view addConstraint:fullHeightConstraint];
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

- (IBAction)orderActionPressed:(id)sender {
    [self.view endEditing:YES];
    
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
    
    [alert addAction:buyAction];
    [alert addAction:sellAction];
    [alert addAction:sellShortAction];
    [alert addAction:buyToCoverAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)orderTypePressed:(id)sender {
    [self.view endEditing:YES];
    
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
    
    [alert addAction:marketAction];
    [alert addAction:limitAction];
    [alert addAction:stopMarketAction];
    [alert addAction:stopLimitAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)orderExpirationPressed:(id)sender {
    [self.view endEditing:YES];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Order Expiration"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* dayAction = [UIAlertAction actionWithTitle:@"Good For The Day" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) { [self changeOrderExpiration:@"day"]; }];
    UIAlertAction* gtcAction = [UIAlertAction actionWithTitle:@"Good Until Canceled" style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) { [self changeOrderExpiration:@"gtc"]; }];

    
    [alert addAction:dayAction];
    [alert addAction:gtcAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)previewOrderPressed:(id)sender {
    [self.view endEditing:YES];
    
    if(readyToTrade) {
        self.tradeSession.orderInfo.quantity = (int)[[sharesInput text] integerValue];
        
        if([self.tradeSession.orderInfo.price.type isEqualToString:@"stopLimit"]) {
            self.tradeSession.orderInfo.price.limitPrice = [NSNumber numberWithDouble:[[leftPriceInput text] doubleValue]];
            self.tradeSession.orderInfo.price.stopPrice = [NSNumber numberWithDouble:[[rightPriceInput text] doubleValue]];
        } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"stopMarket"]) {
            self.tradeSession.orderInfo.price.stopPrice = [NSNumber numberWithDouble:[[leftPriceInput text] doubleValue]];
        } else if([self.tradeSession.orderInfo.price.type isEqualToString:@"limit"]) {
            self.tradeSession.orderInfo.price.limitPrice = [NSNumber numberWithDouble:[[leftPriceInput text] doubleValue]];
        }
        
        [self performSegueWithIdentifier:@"advCalculatorToLoading" sender:self];
    }
    
}

- (IBAction)cancelPressed:(id)sender {
    [TradeItTicket returnToParentApp:self.tradeSession];
}


-(void) sharesInputChanged {
    self.tradeSession.orderInfo.quantity = (int)[sharesInput.text integerValue];
    [self checkIfReadyToTrade];
}

-(void) leftInputChanged {
    if([self.tradeSession.orderInfo.price.type containsString:@"imit"]) {
        self.tradeSession.orderInfo.price.limitPrice = [NSNumber numberWithDouble:[leftPriceInput.text doubleValue]];
    } else {
        self.tradeSession.orderInfo.price.stopPrice = [NSNumber numberWithDouble:[leftPriceInput.text doubleValue]];
    }
    [self checkIfReadyToTrade];
}

-(void) rightInputChanged {
    self.tradeSession.orderInfo.price.stopPrice = [NSNumber numberWithDouble:[leftPriceInput.text doubleValue]];
    [self checkIfReadyToTrade];
}

@end













