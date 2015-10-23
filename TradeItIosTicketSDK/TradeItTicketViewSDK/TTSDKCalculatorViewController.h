//
//  ViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/18/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <LocalAuthentication/LocalAuthentication.h>
#import "TTSDKTicketSession.h"
#import "TTSDKTradeItTicket.h"

#import "TTSDKCalculatorRowLabel.h"
#import "TradeItStockOrEtfOrderPrice.h"
#import "TTSDKLoadingScreenViewController.h"
#import "TTSDKBrokerSelectDetailViewController.h"
#import "TTSDKBaseCalculatorViewController.h"

@interface TTSDKCalculatorViewController : TTSDKBaseCalculatorViewController

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

@end

