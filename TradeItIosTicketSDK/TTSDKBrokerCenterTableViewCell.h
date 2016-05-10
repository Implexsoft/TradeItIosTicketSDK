//
//  TTSDKBrokerCenterTableViewCell.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 5/9/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItBrokerCenterBroker.h"

@interface TTSDKBrokerCenterTableViewCell : UITableViewCell

+(UIColor *) colorFromArray:(NSArray *)colorArray;
-(void) configureWithBroker:(TradeItBrokerCenterBroker *)broker;
-(void) configureSelectedState:(BOOL)selected;
-(void) addImage:(UIImage *)img;

@end
