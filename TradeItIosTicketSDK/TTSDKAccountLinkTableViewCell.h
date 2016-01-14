//
//  TTSDKAccountLinkTableViewCell.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/13/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TTSDKAccountLinkDelegate;

@protocol TTSDKAccountLinkDelegate <NSObject>

@required
-(void)linkToggleDidSelect;

@end


@interface TTSDKAccountLinkTableViewCell : UITableViewCell

@property (nonatomic, weak) id<TTSDKAccountLinkDelegate> delegate;
@property (unsafe_unretained, nonatomic) IBOutlet UISwitch * toggle;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel * accountNameLabel;
@property BOOL linked;
@property NSString * accountName;

-(void) configureCellWithData:(NSDictionary *)data;

@end
