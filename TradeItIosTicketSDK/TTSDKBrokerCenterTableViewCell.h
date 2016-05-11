//
//  TTSDKBrokerCenterTableViewCell.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 5/9/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItBrokerCenterBroker.h"

@protocol TTSDKBrokerCenterDelegate;

@protocol TTSDKBrokerCenterDelegate <NSObject>

@required

-(void) didSelectLink:(NSString *)link withTitle:(NSString *)title;
-(void) didSelectDisclaimer:(BOOL)selected;

@end

@interface TTSDKBrokerCenterTableViewCell : UITableViewCell

@property (nonatomic, weak) id<TTSDKBrokerCenterDelegate> delegate;
@property BOOL disclaimerToggled;

+(UIColor *) colorFromArray:(NSArray *)colorArray;

-(void) configureWithBroker:(TradeItBrokerCenterBroker *)broker;
-(void) configureSelectedState:(BOOL)selected;
-(void) addImage:(UIImage *)img;

@end
