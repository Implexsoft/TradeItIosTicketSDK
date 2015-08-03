//
//  BaseCalculatorViewController.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "TicketSession.h"
#import "TradeItTicket.h"

@interface BaseCalculatorViewController : UIViewController

@property TicketSession * tradeSession;

-(void) setBroker;

@end
