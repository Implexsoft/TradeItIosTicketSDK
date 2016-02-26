//
//  TTSDKPortfolioAccountsTableViewCell.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/7/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKPortfolioAccount.h"

@protocol TTSDKAccountDelegate;

@protocol TTSDKAccountDelegate <NSObject>

@required
-(void)didSelectAuth:(TTSDKPortfolioAccount *)account;

@end

@interface TTSDKPortfolioAccountsTableViewCell : UITableViewCell

@property (nonatomic, weak) id<TTSDKAccountDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *authenticateView;

-(void) configureCellWithAccount:(TTSDKPortfolioAccount *)account;
-(void) hideSeparator;
-(void) showSeparator;

@end
