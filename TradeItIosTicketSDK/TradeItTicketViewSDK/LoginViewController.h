//
//  LoginViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/23/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "TradeItTicket.h"
#import "TicketSession.h"
#import "TradeItAuthenticationInfo.h"
#import "LoadingScreenViewController.h"

@interface LoginViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property TicketSession * tradeSession;

@end
