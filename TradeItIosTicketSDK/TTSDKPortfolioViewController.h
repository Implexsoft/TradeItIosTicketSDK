//
//  TTSDKPortfolioViewController.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/5/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKTicketSession.h"

@interface TTSDKPortfolioViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property TTSDKTicketSession * tradeSession;

@end
