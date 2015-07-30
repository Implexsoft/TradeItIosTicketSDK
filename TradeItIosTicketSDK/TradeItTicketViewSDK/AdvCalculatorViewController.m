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
}

@end

@implementation AdvCalculatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initConstraints];
    [self uiTweaks];
    
    [self changeOrderAction:self.tradeSession.orderInfo.action];
    [self changeOrderType:self.tradeSession.orderInfo.price.type];
    [self changeOrderExpiration:self.tradeSession.orderInfo.expiration];
    
    [[self navigationItem] setTitle: [TradeItTicket getBrokerDisplayString:self.tradeSession.broker]];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self changeOrderAction:self.tradeSession.orderInfo.action];
    [self changeOrderType:self.tradeSession.orderInfo.price.type];
    [self changeOrderExpiration:self.tradeSession.orderInfo.expiration];
    
    [[self navigationItem] setTitle: [TradeItTicket getBrokerDisplayString:self.tradeSession.broker]];
    
    //TODO make sure broker gets updated
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - Change Order

-(void) changeOrderAction: (NSString *) action {
    [orderActionButton setTitle:[TradeItTicket splitCamelCase:action] forState:UIControlStateNormal];
    self.tradeSession.orderInfo.action = action;
}

-(void) changeOrderExpiration: (NSString *) exp {
    
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
}

-(void) setToMarketOrder {
    self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initMarket];
    
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Events

- (IBAction)refreshPressed:(id)sender {
    [self.view endEditing:YES];
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
}

- (IBAction)editPressed:(id)sender {
}

- (IBAction)cancelPressed:(id)sender {
}

@end













