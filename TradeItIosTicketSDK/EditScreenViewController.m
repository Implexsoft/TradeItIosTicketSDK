//
//  EditScreenViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/27/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "EditScreenViewController.h"

@interface EditScreenViewController () {
    
    __weak IBOutlet UIButton *orderActionButton;
    __weak IBOutlet UIButton *orderTypeButton;
    __weak IBOutlet UIButton *orderExpirationButton;
    
    __weak IBOutlet UIButton *brokerButton;
    
    __weak IBOutlet UIButton *calculatorViewButton;
    
    NSArray * linkedBrokers;
    NSArray * brokers;
    NSString * currentCalcScreen;
    
    NSArray * pickerTitles;
    NSArray * pickerValues;
    NSString * currentSelection;
    UIPickerView * currentPicker;
}

@end

@implementation EditScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    orderActionButton.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    orderTypeButton.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    orderExpirationButton.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    brokerButton.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    calculatorViewButton.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];

    orderActionButton.layer.borderWidth = 1;
    orderTypeButton.layer.borderWidth = 1;
    orderExpirationButton.layer.borderWidth = 1;
    brokerButton.layer.borderWidth = 1;
    calculatorViewButton.layer.borderWidth = 1;
    
    [self setCurrentOrderAction];
    [self setCurrentOrderType];
    [self setCurrentOrderExpiration];
    
    linkedBrokers = [TradeItTicket getLinkedBrokersList];
    [brokerButton setTitle:[TradeItTicket getBrokerDisplayString: self.tradeSession.broker] forState:UIControlStateNormal];
    
    NSString * calcScreenPref = [TradeItTicket getCalcScreenPreferance];
    if(calcScreenPref == nil) { calcScreenPref = @"initalCalculatorController"; }
    
    currentCalcScreen = [calcScreenPref isEqualToString: @"initalCalculatorController"] ? @"Calculator" : @"Detail View";
    [calculatorViewButton setTitle:currentCalcScreen forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Changes

-(void) setCurrentOrderAction {
    [orderActionButton setTitle:[TradeItTicket splitCamelCase:self.tradeSession.orderInfo.action] forState:UIControlStateNormal];
}

-(void) setCurrentOrderType {
    [orderTypeButton setTitle:[TradeItTicket splitCamelCase:self.tradeSession.orderInfo.price.type] forState:UIControlStateNormal];
    
    if([self.tradeSession.orderInfo.price.type isEqualToString:@"market"]) {
        self.tradeSession.orderInfo.expiration = @"day";
        [self setCurrentOrderExpiration];
    }
}

-(void) setCurrentOrderExpiration {
    BOOL isGTC = [self.tradeSession.orderInfo.expiration isEqualToString:@"gtc"];
    
    if([self.tradeSession.orderInfo.price.type isEqualToString:@"market"] && isGTC) {
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
    
    if([self.tradeSession.orderInfo.expiration isEqualToString:@"gtc"]) {
        [orderExpirationButton setTitle:@"Good Until Canceled" forState:UIControlStateNormal];
    } else {
        [orderExpirationButton setTitle:@"Good For The Day" forState:UIControlStateNormal];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    [[segue destinationViewController] setTradeSession: self.tradeSession];
    [[segue destinationViewController] setEditMode:YES];
}

//placeholder action used in storyboard segue to unwind
- (IBAction)unwindToEdit:(UIStoryboardSegue *)unwindSegue {
    
}

#pragma mark - Events

- (IBAction)orderActionPressed:(id)sender {
    if(![UIAlertController class]) {
        [self showOldOrderAction];
        return;
    }
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Order Action"
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction * buyOption = [UIAlertAction actionWithTitle:@"Buy" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              self.tradeSession.orderInfo.action = @"buy";
                                                              [self setCurrentOrderAction];
                                                          }];
    
    UIAlertAction * sellOption = [UIAlertAction actionWithTitle:@"Sell" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              self.tradeSession.orderInfo.action = @"sell";
                                                              [self setCurrentOrderAction];
                                                          }];
    
    UIAlertAction * sellShortOption = [UIAlertAction actionWithTitle:@"Sell Short" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              self.tradeSession.orderInfo.action = @"sellShort";
                                                              [self setCurrentOrderAction];
                                                          }];
    
    UIAlertAction * buyToCoverOption = [UIAlertAction actionWithTitle:@"Buy To Cover" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              self.tradeSession.orderInfo.action = @"buyToCover";
                                                              [self setCurrentOrderAction];
                                                          }];
    
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];
    [alert addAction:buyOption];
    [alert addAction:sellOption];
    [alert addAction:sellShortOption];
    [alert addAction:buyToCoverOption];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)orderTypePressed:(id)sender {
    if(![UIAlertController class]) {
        [self showOldOrderType];
        return;
    }
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Order Type"
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction * marketOption = [UIAlertAction actionWithTitle:@"Market" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initMarket];
                                                              [self setCurrentOrderType];
                                                          }];
    
    UIAlertAction * limitOption = [UIAlertAction actionWithTitle:@"Limit" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initLimit:0.0];
                                                              [self setCurrentOrderType];
                                                          }];
    
    UIAlertAction * stopMarketOption = [UIAlertAction actionWithTitle:@"Stop Market" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopMarket:0.0];
                                                              [self setCurrentOrderType];
                                                          }];
    
    UIAlertAction * stopLimitOption = [UIAlertAction actionWithTitle:@"Stop Limit" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopLimit:0.0 :0.0];
                                                              [self setCurrentOrderType];
                                                          }];
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:marketOption];
    [alert addAction:limitOption];
    [alert addAction:stopMarketOption];
    [alert addAction:stopLimitOption];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)orderExpirationPressed:(id)sender {
    if(![UIAlertController class]) {
        [self showOldOrderExp];
        return;
    }
    
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Order Expiration"
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction * dayOption = [UIAlertAction actionWithTitle: @"Good For The Day" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              self.tradeSession.orderInfo.expiration = @"day";
                                                              [self setCurrentOrderExpiration];
                                                          }];
    
    UIAlertAction * gtcOption = [UIAlertAction actionWithTitle: @"Good Until Canceled" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           self.tradeSession.orderInfo.expiration = @"gtc";
                                                           [self setCurrentOrderExpiration];
                                                       }];
    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:dayOption];
    [alert addAction:gtcOption];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)brokerSelectPressed:(id)sender {
    if([linkedBrokers count] > 1) {
        if(![UIAlertController class]) {
            [self showOldBrokerSelect];
            return;
        }
        
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Brokerage"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (NSString * broker in linkedBrokers) {
            UIAlertAction * brokerOption = [UIAlertAction actionWithTitle: [TradeItTicket getBrokerDisplayString:broker] style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      
                                                                      [brokerButton setTitle: [TradeItTicket getBrokerDisplayString:broker] forState:UIControlStateNormal];
                                                                      
                                                                      self.tradeSession.broker = broker;
                                                                      TradeItAuthenticationInfo * creds = [TradeItTicket getStoredAuthenticationForBroker: self.tradeSession.broker];
                                                                      self.tradeSession.authenticationInfo = creds;
                                                                  }];
            [alert addAction:brokerOption];
        }
        
        UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction * action) {}];
        [alert addAction:cancelAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    } else {
        [self performSegueWithIdentifier:@"editToBrokerSelectView" sender:self];
    }
}

- (IBAction)calculatorViewPressed:(id)sender {
    if(![UIAlertController class]) {
        [self showOldScreenSelect];
        return;
    }
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Show Ticket As"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* calcAction = [UIAlertAction actionWithTitle:@"Calculator" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          if([currentCalcScreen isEqualToString:@"Detail View"]) {
                                                              [TradeItTicket setCalcScreenPreferance:@"initalCalculatorController"];
                                                              [TradeItTicket restartTicket:self.tradeSession];
                                                          }
                                                      }];
    
    UIAlertAction* detailAction = [UIAlertAction actionWithTitle:@"Detail View" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {
                                                          if([currentCalcScreen isEqualToString:@"Calculator"]) {
                                                              [TradeItTicket setCalcScreenPreferance:@"advCalculatorController"];
                                                              [TradeItTicket restartTicket:self.tradeSession];
                                                          }
                                                      }];
    
    
    [alert addAction:calcAction];
    [alert addAction:detailAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - iOS7 Fallbacks

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) showOldScreenSelect {
    pickerTitles = @[@"Calculator",@"Detail View"];
    pickerValues = @[@"initalCalculatorController",@"advCalculatorController"];
    currentSelection = currentCalcScreen;
    
    CustomIOSAlertView * alert = [[CustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Show Ticket As"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
        if([currentCalcScreen isEqualToString:@"Calculator"] && [currentSelection isEqualToString:@"advCalculatorController"]) {
            [TradeItTicket setCalcScreenPreferance:@"advCalculatorController"];
            [TradeItTicket restartTicket:self.tradeSession];
        } else if([currentCalcScreen isEqualToString:@"Detail View"] && [currentSelection isEqualToString:@"initalCalculatorController"]) {
            [TradeItTicket setCalcScreenPreferance:@"initalCalculatorController"];
            [TradeItTicket restartTicket:self.tradeSession];
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
        
        if([currentCalcScreen isEqualToString:@"Detail View"]){
            [currentPicker selectRow:1 inComponent:0 animated:NO];
        }
    });
}

-(void) showOldBrokerSelect {
    NSMutableArray * titles = [[NSMutableArray alloc] init];
    NSMutableArray * values = [[NSMutableArray alloc] init];
    
    for (NSString * broker in linkedBrokers) {
        [titles addObject:[TradeItTicket getBrokerDisplayString:broker]];
        [values addObject:broker];
    }
    
    pickerTitles = titles;
    pickerValues = values;
    currentSelection = self.tradeSession.broker;
    
    CustomIOSAlertView * alert = [[CustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Select Brokerage"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 1) {
            [brokerButton setTitle: [TradeItTicket getBrokerDisplayString:currentSelection] forState:UIControlStateNormal];
            
            self.tradeSession.broker = currentSelection;
            TradeItAuthenticationInfo * creds = [TradeItTicket getStoredAuthenticationForBroker: self.tradeSession.broker];
            self.tradeSession.authenticationInfo = creds;
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
        
        int count = 0;
        for (NSString * broker in linkedBrokers) {
            if([broker isEqualToString:self.tradeSession.broker]) {
                [currentPicker selectRow:count inComponent:0 animated:NO];
            }
            
            count++;
        }
    });
}

-(void) changeOrderAction: (NSString *) action {
    self.tradeSession.orderInfo.action = action;
    [self setCurrentOrderAction];
}

-(void) changeOrderType: (NSString *) type {
    if([type isEqualToString:@"limit"]){
        self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initLimit:0.0];
    } else if([type isEqualToString:@"stopMarket"]){
        self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopMarket:0.0];
    } else if([type isEqualToString:@"stopLimit"]){
        self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initStopLimit:0.0 :0.0];
    } else {
        self.tradeSession.orderInfo.price = [[TradeitStockOrEtfOrderPrice alloc] initMarket];
    }
    
    [self setCurrentOrderType];
}

-(void) changeOrderExpiration: (NSString *) exp {
    self.tradeSession.orderInfo.expiration = exp;
    [self setCurrentOrderExpiration];
}

-(void) showOldOrderAction {
    pickerTitles = @[@"Buy",@"Sell",@"Buy to Cover",@"Sell Short"];
    pickerValues = @[@"buy",@"sell",@"buyToCover",@"sellShort"];
    currentSelection = self.tradeSession.orderInfo.action;
    
    CustomIOSAlertView * alert = [[CustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Order Action"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
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
    
    CustomIOSAlertView * alert = [[CustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Order Action"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
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
    
    CustomIOSAlertView * alert = [[CustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Order Action"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
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

@end
































