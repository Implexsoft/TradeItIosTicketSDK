//
//  TTSDKPortfolioViewController.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/5/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKPortfolioHoldingTableViewCell.h"
#import "TTSDKPortfolioAccountsTableViewCell.h"

@interface TTSDKPortfolioViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, TTSDKPositionDelegate, TTSDKAccountDelegate>

@end
