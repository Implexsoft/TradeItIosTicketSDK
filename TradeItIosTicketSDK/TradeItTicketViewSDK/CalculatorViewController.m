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
    
    [self uiTweaks];
    [self setTicketToMarketOrder];
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

#pragma Order Type Changes

- (void) setTicketToMarketOrder {
    [lastPriceRowItem setDefaultsToUI];
    currentPriceCalcRowItem = lastPriceRowItem;
    [self removeStopPrice];
    [self changeCalcRowInput:sharesRowItem];
    
    [[[self tradeSession] orderInfo] setPrice: [[TradeitStockOrEtfOrderPrice alloc]initMarket]];
    
    [self updateEstimatedCost];
}
- (void) setTicketToLimitOrder {
    [limitPriceRowItem setDefaultsToUI];
    currentPriceCalcRowItem = limitPriceRowItem;
    [self removeStopPrice];
    
    if(activeCalcRowItem == stopLimitPriceRowItem) {
        [self changeCalcRowInput:sharesRowItem];
    }
    
    [[[self tradeSession] orderInfo] setPrice: [[TradeitStockOrEtfOrderPrice alloc]initLimit:0.0]];
    //TODO set limit price
    
    [self updateEstimatedCost];
}
- (void) setTicketToStopMarketOrder {
    [stopPriceRowItem setDefaultsToUI];
    currentPriceCalcRowItem = stopPriceRowItem;
    [self removeStopPrice];
    
    if(activeCalcRowItem == stopLimitPriceRowItem) {
        [self changeCalcRowInput:sharesRowItem];
    }
    
    [[[self tradeSession] orderInfo] setPrice: [[TradeitStockOrEtfOrderPrice alloc]initStopMarket:0.0]];
    //TODO set limit price
    
    [self updateEstimatedCost];
}
- (void) setTicketToStopLimitOrder {
    [stopLimitPriceRowItem setDefaultsToUI];
    [limitPriceRowItem setDefaultsToUI];
    currentPriceCalcRowItem = limitPriceRowItem;
    [self showStopPrice];
    
    [[[self tradeSession] orderInfo] setPrice: [[TradeitStockOrEtfOrderPrice alloc]initStopLimit:0.0 :0.0]];
    //TODO set limit price
    //TODO set stop limit price
    
    [self updateEstimatedCost];
}

#pragma UI Changes

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

#pragma Events

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
}


@end


























