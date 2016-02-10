//
//  TTSDKPortfolioHoldingTableViewCell.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/6/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItPosition.h"

@interface TTSDKPortfolioHoldingTableViewCell : UITableViewCell

-(void) configureCellWithPosition:(TradeItPosition *)position;
-(void) hideSeparator;
-(void) showSeparator;

@end
