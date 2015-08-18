//
//  BrokerSelectViewController.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/20/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TicketSession.h"
#import "TradeItTicket.h"
#import "BrokerSelectDetailViewController.h"
#import "TTSDKMBProgressHUD.h"

@interface BrokerSelectViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property TicketSession * tradeSession;
@property BOOL editMode;

@end
