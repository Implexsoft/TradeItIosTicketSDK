//
//  TTSDKAccountsViewController.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/16/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKTicketSession.h"
#import "TTSDKTradeItTicket.h"


@interface TTSDKAccountsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property TTSDKTicketSession * tradeSession;

@end
