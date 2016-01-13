//
//  BrokerSelectViewController.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/20/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKTicketSession.h"
#import "TTSDKTradeItTicket.h"
#import "TTSDKLoginViewController.h"
#import "TTSDKMBProgressHUD.h"

@interface TTSDKBrokerSelectViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property TTSDKTicketSession * tradeSession;
@property BOOL editMode;

@end
