//
//  ViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/18/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "CalculatorViewController.h"

@interface CalculatorViewController () {
    __weak IBOutlet UIButton * tradeButton;
    
    __weak IBOutlet UILabel *estimatedCostLabel;
    
    __weak IBOutlet UIView * calcRowView;
    __weak IBOutlet UIButton * stopPriceValueButton;
    __weak IBOutlet UIButton * stopPriceLabelButton;
    __weak IBOutlet UIButton * priceValueButton;
    __weak IBOutlet UIButton * priceLabelButton;
    __weak IBOutlet UIButton * sharesValueButton;
    __weak IBOutlet UIButton * sharesLabelButton;

    __weak IBOutlet UIButton * marketOrderButton;
    __weak IBOutlet UIButton * limitOrderButton;
    __weak IBOutlet UIButton * stopMarketOrderButton;
    __weak IBOutlet UIButton * stopLimitOrderButton;
    
    __weak IBOutlet UIButton * refreshAndDecimalButton;
    __weak IBOutlet UIButton * backspaceButton;

    __weak IBOutlet UIButton *footerMessageButton;
    
    
    NSLayoutConstraint * priceValueToCalcRowViewConstraint;
    NSLayoutConstraint * stopPriceLabelNoWidthConstraint;
    NSLayoutConstraint * stopPriceLabelFullWidthConstraint;
    NSLayoutConstraint * stopPriceValueWidthConstraint;
    
    CalculatorRowLabel * sharesRowItem;
    CalculatorRowLabel * lastPriceRowItem;
    CalculatorRowLabel * limitPriceRowItem;
    CalculatorRowLabel * stopPriceRowItem;
    CalculatorRowLabel * stopLimitPriceRowItem;
    
    CalculatorRowLabel * activeCalcRowItem;
    CalculatorRowLabel * currentPriceCalcRowItem;
    
    NSDictionary * footerMessages;
    
    NSString * currentOrderType;
    BOOL readyToTrade;
}


@end

@implementation CalculatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    readyToTrade = NO;
    [self initFooterMessages];
    
    sharesRowItem = [CalculatorRowLabel getSharesLabel:sharesLabelButton uiValue:sharesValueButton];
    lastPriceRowItem = [CalculatorRowLabel getLastPriceLabel:priceLabelButton uiValue:priceValueButton];
    limitPriceRowItem = [CalculatorRowLabel getLimitPriceLabel:priceLabelButton uiValue:priceValueButton];
    stopPriceRowItem = [CalculatorRowLabel getStopPriceLabel:priceLabelButton uiValue:priceValueButton];
    stopLimitPriceRowItem = [CalculatorRowLabel getStopLimitPriceLabel:stopPriceLabelButton uiValue:stopPriceValueButton];
    
    activeCalcRowItem = sharesRowItem;
    [sharesRowItem setActive];
    
    lastPriceRowItem.currentValueStack = [NSString stringWithFormat: @"%g", self.tradeSession.lastPrice];
    [lastPriceRowItem setUIToStack];
    
    [self updateTradeLabels];
    [self uiTweaks];
    [self setTicketView];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateTradeLabels];
    [self setTicketView];
    [self setBroker];
}

-(void) setTicketView {
    if(!currentOrderType || ![currentOrderType isEqualToString:self.tradeSession.orderInfo.price.type]) {
        currentOrderType = self.tradeSession.orderInfo.price.type ? self.tradeSession.orderInfo.price.type : @"market";
        if([currentOrderType isEqualToString:@"market"]) {
            [self setTicketToMarketOrder];
        } else if([currentOrderType isEqualToString:@"limit"]) {
            [self setTicketToLimitOrder];
        } else if([currentOrderType isEqualToString:@"stopMarket"]) {
            [self setTicketToStopMarketOrder];
        } else {
            [self setTicketToStopLimitOrder];
        }
    }
    
    [self setFooterMessage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) changeCalcRowInput:(CalculatorRowLabel *)newItem {
    if(newItem != lastPriceRowItem) {
        [activeCalcRowItem setPassive];
        activeCalcRowItem = newItem;
        [activeCalcRowItem setActive];
    
        if(newItem != sharesRowItem) {
            [self refreshButtonShowDecimal];
        } else {
            [self refreshButtonShowRefresh];
        }
        
        [self updateEstimatedCost];
    }
}

-(void) updateEstimatedCost {
    NSInteger shares = [sharesRowItem.currentValueStack integerValue];
    double price = [currentPriceCalcRowItem.currentValueStack doubleValue];
    
    double estimatedCost = shares * price;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSString * equalitySign = [self.tradeSession.orderInfo.price.type containsString:@"arket"] ? @"\u2248" : @"=";
    NSString * formattedString = [NSString stringWithFormat:@"%@ %@", equalitySign, [formatter stringFromNumber: [NSNumber numberWithDouble:estimatedCost]]];
    
    [estimatedCostLabel setText:formattedString];
    [[[self tradeSession] orderInfo] setQuantity: (int) [sharesRowItem.currentValueStack integerValue]];
    [self updateOrderPrice];
    [self checkIfReadyToTrade];
}

-(void) updateOrderPrice {
    if(activeCalcRowItem == limitPriceRowItem) {
        [[[[self tradeSession]orderInfo]price] setLimitPrice: [NSNumber numberWithDouble: [[activeCalcRowItem currentValueStack] doubleValue]]];
        
    } else if(activeCalcRowItem == stopPriceRowItem || activeCalcRowItem == stopLimitPriceRowItem) {
        [[[[self tradeSession]orderInfo]price] setStopPrice: [NSNumber numberWithDouble: [[activeCalcRowItem currentValueStack] doubleValue]]];
    }
}

-(void) checkIfReadyToTrade {
    NSInteger shares = [sharesRowItem.currentValueStack integerValue];
    double price = [currentPriceCalcRowItem.currentValueStack doubleValue];
    double stopLimitPrice = [stopLimitPriceRowItem.currentValueStack doubleValue];
    BOOL isStopLimitOrder = [self.tradeSession.orderInfo.price.type isEqualToString:@"stopLimitOrder"];
    
    
    if(price > 0 && shares > 0) {
        if(!(isStopLimitOrder && stopLimitPrice <= 0)) {
            readyToTrade = YES;
            [tradeButton setBackgroundColor:[UIColor colorWithRed:20.0f/255.0f green:63.0f/255.0f blue:119.0f/255.0f alpha:1.0f]];
            return;
        }
    }
    
    readyToTrade = NO;
    [tradeButton setBackgroundColor:[UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:200.0f/255.0f alpha:1.0f]];
}

//I'm so sorry for anyone who has to read this
//there really should be a better way to do this
//maybe delegates?
-(void) refreshPrice {
    if(self.tradeSession.refreshQuote != nil) {
        //perform network request (most likely) off the main thread
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0),  ^(void){
            self.tradeSession.refreshQuote(self.tradeSession.orderInfo.symbol, ^(double lastPrice, double priceChangeDollar, double priceChangePercentage, NSString * quoteUpdateTime){
                
                //return to main thread as this triggers a UI change
                dispatch_async(dispatch_get_main_queue(), ^{
                    lastPriceRowItem.currentValueStack = [NSString stringWithFormat: @"%g", lastPrice];
                    [lastPriceRowItem setUIToStack];
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
                    lastPriceRowItem.currentValueStack = [NSString stringWithFormat: @"%g", price];
                    [lastPriceRowItem setUIToStack];
                });
            });
        });
        
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([segue.identifier isEqualToString:@"calculatorToLoading"]){
        [[segue destinationViewController] setActionToPerform: @"sendLoginReviewRequest"];
    } else if([segue.identifier isEqualToString:@"calculatorToBrokerSelectDetail"]) {
        [[segue destinationViewController] setCancelToParent: YES];
    }
    
    [[segue destinationViewController] setTradeSession: self.tradeSession];
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
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

#pragma mark - Order Type Changes

- (void) setTicketToMarketOrder {
    [lastPriceRowItem setDefaultsToUI];
    currentPriceCalcRowItem = lastPriceRowItem;
    [self removeStopPrice];
    [self changeCalcRowInput:sharesRowItem];
    
    [[[self tradeSession] orderInfo] setExpiration:@"day"];
    
    [[[self tradeSession] orderInfo] setPrice: [[TradeitStockOrEtfOrderPrice alloc]initMarket]];
    
    [self updateEstimatedCost];
    [self setOrderButtonActive: marketOrderButton];
    [self setFooterMessage];
}
- (void) setTicketToLimitOrder {
    [limitPriceRowItem setDefaultsToUI];
    currentPriceCalcRowItem = limitPriceRowItem;
    [self removeStopPrice];
    
    if(activeCalcRowItem == stopLimitPriceRowItem) {
        [self changeCalcRowInput:sharesRowItem];
    }
    
    [[[self tradeSession] orderInfo] setPrice: [[TradeitStockOrEtfOrderPrice alloc]initLimit:[[limitPriceRowItem currentValueStack] doubleValue]]];
    
    [self updateEstimatedCost];
    [self setOrderButtonActive: limitOrderButton];
    [self setFooterMessage];
}
- (void) setTicketToStopMarketOrder {
    [stopPriceRowItem setDefaultsToUI];
    currentPriceCalcRowItem = stopPriceRowItem;
    [self removeStopPrice];
    
    if(activeCalcRowItem == stopLimitPriceRowItem) {
        [self changeCalcRowInput:sharesRowItem];
    }
    
    [[[self tradeSession] orderInfo] setPrice: [[TradeitStockOrEtfOrderPrice alloc]initStopMarket:[[stopPriceRowItem currentValueStack] doubleValue]]];
    
    [self updateEstimatedCost];
    [self setOrderButtonActive: stopMarketOrderButton];
    [self setFooterMessage];
}
- (void) setTicketToStopLimitOrder {
    [stopLimitPriceRowItem setDefaultsToUI];
    [limitPriceRowItem setDefaultsToUI];
    currentPriceCalcRowItem = limitPriceRowItem;
    [self showStopPrice];
    
    [[[self tradeSession] orderInfo] setPrice: [[TradeitStockOrEtfOrderPrice alloc]initStopLimit:[[stopLimitPriceRowItem currentValueStack] doubleValue] :[[stopPriceRowItem currentValueStack] doubleValue]]];
    
    [self updateEstimatedCost];
    [self setOrderButtonActive: stopLimitOrderButton];
    [self setFooterMessage];
}

- (void) setOrderButtonActive:(UIButton *) activeButton {
    marketOrderButton.backgroundColor = [UIColor whiteColor];
    limitOrderButton.backgroundColor = [UIColor whiteColor];
    stopMarketOrderButton.backgroundColor = [UIColor whiteColor];
    stopLimitOrderButton.backgroundColor = [UIColor whiteColor];
    
    activeButton.backgroundColor = [UIColor colorWithRed:226.0f/255.0f green:238.0f/255.0f blue:246.0f/255.0f alpha:1.0f];
}

#pragma mark - UI Changes

//Things can't be done in IB
- (void)uiTweaks {
    [self defineContraints];
    [tradeButton.layer setCornerRadius:5.0f];
    stopMarketOrderButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    stopLimitOrderButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [[backspaceButton imageView] setContentMode: UIViewContentModeScaleAspectFit];
    [backspaceButton setImage:[UIImage imageNamed:@"TradeItIosTicketSDK.bundle/backspace.png"] forState:UIControlStateNormal];
    [self refreshButtonShowRefresh];
    
    footerMessageButton.titleLabel.numberOfLines = 0;
    footerMessageButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}

-(void) updateTradeLabels {
    NSString * tradeString = [NSString stringWithFormat:@"%@ %@",
                              [TradeItTicket splitCamelCase: [[[self tradeSession] orderInfo] action]],
                              [[[self tradeSession] orderInfo] symbol]];
    
    [[self navigationItem] setTitle: tradeString];
    [tradeButton setTitle:tradeString forState:UIControlStateNormal];
}

-(void) refreshButtonShowRefresh {
    [refreshAndDecimalButton setTitle:@"" forState:UIControlStateNormal];
    [[refreshAndDecimalButton imageView] setContentMode: UIViewContentModeScaleAspectFit];
    [refreshAndDecimalButton setImage:[UIImage imageNamed:@"TradeItIosTicketSDK.bundle/refresh.png"] forState:UIControlStateNormal];
}

-(void) refreshButtonShowDecimal {
    [refreshAndDecimalButton setImage:nil forState:UIControlStateNormal];
    [refreshAndDecimalButton setTitle:@"." forState:UIControlStateNormal];
}

- (void) removeStopPrice {
    [self.view addConstraint:stopPriceLabelNoWidthConstraint];
    [self.view removeConstraint:stopPriceLabelFullWidthConstraint];
    [self.view addConstraint:stopPriceValueWidthConstraint];
    [self.view addConstraint:priceValueToCalcRowViewConstraint];
}

- (void) showStopPrice {
    [self.view removeConstraint:stopPriceLabelNoWidthConstraint];
    [self.view addConstraint:stopPriceLabelFullWidthConstraint];
    [self.view removeConstraint:stopPriceValueWidthConstraint];
    [self.view removeConstraint:priceValueToCalcRowViewConstraint];
}

- (void) defineContraints {
    priceValueToCalcRowViewConstraint = [NSLayoutConstraint
                                         constraintWithItem:priceValueButton
                                         attribute:NSLayoutAttributeTrailing
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:calcRowView
                                         attribute:NSLayoutAttributeTrailing
                                         multiplier:1
                                         constant:0];
    priceValueToCalcRowViewConstraint.priority = 900;
    
    stopPriceLabelNoWidthConstraint = [NSLayoutConstraint
                      constraintWithItem:stopPriceLabelButton
                      attribute:NSLayoutAttributeWidth
                      relatedBy:NSLayoutRelationEqual
                      toItem:nil
                      attribute:NSLayoutAttributeNotAnAttribute
                      multiplier:1
                      constant:0];
    stopPriceLabelNoWidthConstraint.priority = 900;
    
    stopPriceLabelFullWidthConstraint = [NSLayoutConstraint
                                     constraintWithItem:stopPriceLabelButton
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                     toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1
                                     constant:55];
    stopPriceLabelFullWidthConstraint.priority = 900;
    
    stopPriceValueWidthConstraint = [NSLayoutConstraint
                       constraintWithItem:stopPriceValueButton
                       attribute:NSLayoutAttributeWidth
                       relatedBy:NSLayoutRelationEqual
                       toItem:nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1
                       constant:0];
    stopPriceValueWidthConstraint.priority = 900;
}

-(void) initFooterMessages {
    footerMessages = @{
       @"marketday": @"Your market order is good for the day\nand will be executed at the next price.",
       @"marketgtc": @"Your market order is good until canceled\nand will be executed at the next price.",
       @"limitday": @"Your limit order is good for the day\nand will be executed at your limit price or better.",
       @"limitgtc": @"Your limit order is good until canceled\nand will be executed at your limit price or better.",
       @"stopMarketday": @"Your stop market order is good for the day\nand will be activated when your stop price is reached.",
       @"stopMarketgtc": @"Your stop market order is good until canceled\nand will be activated when your stop price is reached.",
       @"stopLimitday": @"Your stop limit order is good for the day\nand will be activated when your stop price is reached.",
       @"stopLimitgtc": @"Your stop limit order is good until canceled\nand will be activated when your stop price is reached."
    };
}

-(void) setFooterMessage {
    NSMutableString * messageType = [NSMutableString stringWithString: self.tradeSession.orderInfo.price.type];
    [messageType appendString:self.tradeSession.orderInfo.expiration];
    
    [footerMessageButton setTitle:footerMessages[messageType] forState:UIControlStateNormal];
}

#pragma mark - Events

- (IBAction)calcPadButtonPressed:(id)sender {
    UIButton *button = (UIButton *) sender;
    
    activeCalcRowItem.currentValueStack = [NSString stringWithFormat: @"%@%i", activeCalcRowItem.currentValueStack, (int) button.tag];

    [activeCalcRowItem setUIToStack];
    [self updateEstimatedCost];
}

- (IBAction)backspacePressed:(id)sender {
    if([activeCalcRowItem.currentValueStack length] > 0) {
        activeCalcRowItem.currentValueStack = [activeCalcRowItem.currentValueStack substringToIndex:[activeCalcRowItem.currentValueStack length] - 1];
        [activeCalcRowItem setUIToStack];
        [self updateEstimatedCost];
    }
}

- (IBAction)refreshAndDecimalPressed:(id)sender {
    if(activeCalcRowItem != sharesRowItem) {
        if(![activeCalcRowItem.currentValueStack containsString:@"."]) {
            activeCalcRowItem.currentValueStack = [NSString stringWithFormat: @"%@.", activeCalcRowItem.currentValueStack];
            [activeCalcRowItem setUIToStack];
            [self updateEstimatedCost];
        }
    } else {
        [self refreshPrice];
    }
}

- (IBAction)marketOrderPressed:(id)sender {
    [self setTicketToMarketOrder];
}

- (IBAction)limitOrderPressed:(id)sender {
    [self setTicketToLimitOrder];
}

- (IBAction)stopMarketOrderPressed:(id)sender {
    [self setTicketToStopMarketOrder];
}

- (IBAction)stopLimitOrderPressed:(id)sender {
    [self setTicketToStopLimitOrder];
}

- (IBAction)sharesButtonPressed:(id)sender {
    [self changeCalcRowInput:sharesRowItem];
}

- (IBAction)priceButtonPressed:(id)sender {
    [self changeCalcRowInput:currentPriceCalcRowItem];
}

- (IBAction)stopPriceButtonPressed:(id)sender {
    [self changeCalcRowInput:stopLimitPriceRowItem];
}

- (IBAction)CancelPressed:(id)sender {
    [TradeItTicket returnToParentApp:self.tradeSession];
}

- (IBAction)tradeButtonPressed:(id)sender {
    if(readyToTrade) {
        [self performSegueWithIdentifier:@"calculatorToLoading" sender:self];
    }
}

- (IBAction)editButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"calculatorToEdit" sender:self];
}

- (IBAction)footerButtonMessagePressed:(id)sender {
    [self performSegueWithIdentifier:@"calculatorToEdit" sender:self];
}



@end


























