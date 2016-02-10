//
//  TTSDKPortfolioAccountsTableViewCell.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/7/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTSDKPortfolioAccountsTableViewCell : UITableViewCell

-(void) configureCellWithAccount:(NSDictionary *)account;
-(void) configureCellWithDetails:(NSDictionary *)data;

@end
