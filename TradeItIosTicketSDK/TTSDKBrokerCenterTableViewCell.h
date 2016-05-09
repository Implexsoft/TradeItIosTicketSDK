//
//  TTSDKBrokerCenterTableViewCell.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 5/9/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTSDKBrokerCenterTableViewCell : UITableViewCell

-(void) configureWithData:(NSDictionary *)data;
-(void) configureSelectedState:(BOOL)selected;
-(void) addImage:(UIImage *)img;

@end
