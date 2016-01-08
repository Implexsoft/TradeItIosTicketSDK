//
//  TTSDKPortfolioHoldingTableViewCell.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/6/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTSDKPortfolioHoldingTableViewCell : UITableViewCell

-(void) configureCellWithData:(NSDictionary *)data;
-(void) hideSeparator;
-(void) showSeparator;

@end
