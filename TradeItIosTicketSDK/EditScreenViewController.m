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
    
    //TODO - possibly remove detail view for iphone < 4s
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
        
        UIAlertView * alert;
        alert = [[UIAlertView alloc] initWithTitle:@"Invalid Expiration" message:@"Market orders are Good For The Day only." delegate: self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        
        [alert show];
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

@end
































