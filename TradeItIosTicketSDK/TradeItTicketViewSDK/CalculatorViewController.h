//
//  ViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/18/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "CalculatorRowLabel.h"
#import "TradeItStockOrEtfOrderPrice.h"
#import "TicketSession.h"
#import "LoadingScreenViewController.h"
#import "BrokerSelectDetailViewController.h"

@interface CalculatorViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

-(IBAction)calcPadButtonPressed:(id)sender;
-(IBAction)backspacePressed:(id)sender;
-(IBAction)refreshAndDecimalPressed:(id)sender;

- (IBAction)marketOrderPressed:(id)sender;
- (IBAction)limitOrderPressed:(id)sender;
- (IBAction)stopMarketOrderPressed:(id)sender;
- (IBAction)stopLimitOrderPressed:(id)sender;

- (IBAction)sharesButtonPressed:(id)sender;
- (IBAction)priceButtonPressed:(id)sender;
- (IBAction)stopPriceButtonPressed:(id)sender;

@property TicketSession * tradeSession;

@end

