//
//  TTSDKTableViewController.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 4/8/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKTradeItTicket.h"
#import "TTSDKUtils.h"
#import "TradeItStyles.h"

@interface TTSDKTableViewController : UITableViewController

@property TTSDKTradeItTicket * ticket;
@property TTSDKUtils * utils;
@property TradeItStyles * styles;

-(void) setViewStyles;
-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message;
-(void) showWebViewWithURL:(NSString *)url andTitle:(NSString *)title;

@end
