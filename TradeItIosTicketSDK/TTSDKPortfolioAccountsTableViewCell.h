//
//  TTSDKPortfolioAccountsTableViewCell.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/7/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKPortfolioAccount.h"

@interface TTSDKPortfolioAccountsTableViewCell : UITableViewCell

-(void) configureCellWithAccount:(TTSDKPortfolioAccount *)account;

@end
