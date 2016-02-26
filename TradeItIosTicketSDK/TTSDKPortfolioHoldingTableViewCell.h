//
//  TTSDKPortfolioHoldingTableViewCell.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/6/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItPosition.h"
#import "TTSDKPosition.h"

@protocol TTSDKPositionDelegate;

@protocol TTSDKPositionDelegate <NSObject>

@required
-(void)didSelectBuy:(TTSDKPosition *)position;
-(void)didSelectSell:(TTSDKPosition *)position;

@end

@interface TTSDKPortfolioHoldingTableViewCell : UITableViewCell

@property (nonatomic, weak) id<TTSDKPositionDelegate> delegate;

-(void) configureCellWithPosition:(TradeItPosition *)position;
-(void) hideSeparator;
-(void) showSeparator;

@end
