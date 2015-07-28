//
//  BrokerSelectDetailViewController.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadingScreenViewController.h"
#import "TicketSession.h"

@interface BrokerSelectDetailViewController : UIViewController <UITextFieldDelegate>

@property TicketSession * tradeSession;
@property BOOL cancelToParent;

@property NSString * addBroker;

@end
