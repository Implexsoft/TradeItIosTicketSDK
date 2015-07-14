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

    NSLayoutConstraint * priceValueToCalcRowViewConstraint;
    NSLayoutConstraint * stopPriceLabelWidthConstraint;
    NSLayoutConstraint * stopPriceValueWidthConstraint;
    
    CalculatorRowLabel * sharesRowItem;
    CalculatorRowLabel * lastPriceRowItem;
    CalculatorRowLabel * limitPriceRowItem;
    CalculatorRowLabel * stopPriceRowItem;
    CalculatorRowLabel * stopLimitPriceRowItem;
    
    CalculatorRowLabel * activeCalcRowItem;
    CalculatorRowLabel * currentPriceCalcRowItem;
    
    NSString * currentOrderType;
}


@end

@implementation CalculatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    sharesRowItem = [CalculatorRowLabel getSharesLabel:sharesLabelButton uiValue:sharesValueButton];
    lastPriceRowItem = [CalculatorRowLabel getLastPriceLabel:priceLabelButton uiValue:priceValueButton];
    limitPriceRowItem = [CalculatorRowLabel getLimitPriceLabel:priceLabelButton uiValue:priceValueButton];
    stopPriceRowItem = [CalculatorRowLabel getStopPriceLabel:priceLabelButton uiValue:priceValueButton];
    stopLimitPriceRowItem = [CalculatorRowLabel getStopLimitPriceLabel:stopPriceLabelButton uiValue:stopPriceValueButton];
    
    activeCalcRowItem = sharesRowItem;
    [sharesRowItem setActive];
    
    lastPriceRowItem.currentValueStack = [NSString stringWithFormat: @"%g", self.tradeSession.lastPrice];
    
    [self updateTradeLabels];
    [self uiTweaks];
    [self setTicketView];
    [lastPriceRowItem setUIToStack];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateTradeLabels];
    [self setTicketView];
}

-(void) setTicketView {
    if(!currentOrderType || ![currentOrderType isEqualToString:[[self tradeSession] orderType]]) {
        currentOrderType = [[self tradeSession] orderType] ? [[self tradeSession] orderType] : @"market";
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
    
    NSString * formattedString = [NSString stringWithFormat:@"\u2248 %@", [formatter stringFromNumber: [NSNumber numberWithDouble:estimatedCost]]];
    
    [estimatedCostLabel setText:formattedString];
    [[[self tradeSession] orderInfo] setQuantity: [sharesRowItem.currentValueStack integerValue]];
    [self updateOrderPrice];
}

-(void) updateOrderPrice {
    if(activeCalcRowItem == limitPriceRowItem) {
        [[[[self tradeSession]orderInfo]price] setLimitPrice: [NSNumber numberWithDouble: [[activeCalcRowItem currentValueStack] doubleValue]]];
        
    } else if(activeCalcRowItem == stopPriceRowItem || activeCalcRowItem == stopLimitPriceRowItem) {
        [[[[self tradeSession]orderInfo]price] setStopPrice: [NSNumber numberWithDouble: [[activeCalcRowItem currentValueStack] doubleValue]]];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    [[segue destinationViewController] setTradeSession: self.tradeSession];
}

#pragma mark - Order Type Changes

- (void) setTicketToMarketOrder {
    [lastPriceRowItem setDefaultsToUI];
    currentPriceCalcRowItem = lastPriceRowItem;
    [self removeStopPrice];
    [self changeCalcRowInput:sharesRowItem];
    
    [[[self tradeSession] orderInfo] setPrice: [[TradeitStockOrEtfOrderPrice alloc]initMarket]];
    
    [self updateEstimatedCost];
    [self setOrderButtonActive: marketOrderButton];
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
}
- (void) setTicketToStopLimitOrder {
    [stopLimitPriceRowItem setDefaultsToUI];
    [limitPriceRowItem setDefaultsToUI];
    currentPriceCalcRowItem = limitPriceRowItem;
    [self showStopPrice];
    
    [[[self tradeSession] orderInfo] setPrice: [[TradeitStockOrEtfOrderPrice alloc]initStopLimit:[[stopLimitPriceRowItem currentValueStack] doubleValue] :[[stopPriceRowItem currentValueStack] doubleValue]]];
    
    [self updateEstimatedCost];
    [self setOrderButtonActive: stopLimitOrderButton];
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
    [backspaceButton setImage:[UIImage imageNamed:@"TradeItIosTicketSDK.bundle/Backspace"] forState:UIControlStateNormal];
    [self refreshButtonShowRefresh];
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
    [refreshAndDecimalButton setImage:[UIImage imageNamed:@"TradeItIosTicketSDK.bundle/Refresh"] forState:UIControlStateNormal];
}

-(void) refreshButtonShowDecimal {
    [refreshAndDecimalButton setImage:nil forState:UIControlStateNormal];
    [refreshAndDecimalButton setTitle:@"." forState:UIControlStateNormal];
}

- (void) removeStopPrice {
    [self.view addConstraint:stopPriceLabelWidthConstraint];
    [self.view addConstraint:stopPriceValueWidthConstraint];
    [self.view addConstraint:priceValueToCalcRowViewConstraint];
}

- (void) showStopPrice {
    [self.view removeConstraint:stopPriceLabelWidthConstraint];
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
    
    stopPriceLabelWidthConstraint = [NSLayoutConstraint
                      constraintWithItem:stopPriceLabelButton
                      attribute:NSLayoutAttributeWidth
                      relatedBy:NSLayoutRelationEqual
                      toItem:nil
                      attribute:NSLayoutAttributeNotAnAttribute
                      multiplier:1
                      constant:0];
    stopPriceLabelWidthConstraint.priority = 900;
    
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

#pragma mark - Events

- (IBAction)calcPadButtonPressed:(id)sender {
    UIButton *button = (UIButton *) sender;
    
    activeCalcRowItem.currentValueStack = [NSString stringWithFormat: @"%@%i", activeCalcRowItem.currentValueStack, button.tag];

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

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    NSString * symbol = [[[self tradeSession] orderInfo] symbol];
    NSString * publisherApp = [[self tradeSession] publisherApp];

    [[self tradeSession] reset];
    [[[self tradeSession] orderInfo] setSymbol: symbol];
    [[self tradeSession] setPublisherApp: publisherApp];
}

- (IBAction)CancelPressed:(id)sender {
    [[[self tradeSession] parentView] dismissViewControllerAnimated:YES completion:[[self tradeSession] callback]];
}

@end


























