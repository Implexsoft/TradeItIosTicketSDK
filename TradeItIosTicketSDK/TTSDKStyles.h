//
//  TTSDKStyles.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 4/7/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TTSDKStyles : NSObject

@property UIColor * warningColor;
@property UIColor * lossColor;
@property UIColor * gainColor;

@property UIColor * pageBackgroundColor;
@property UIColor * navigationBarBackgroundColor;
@property UIColor * navigationBarItemColor;
@property UIColor * navigationBarTitleColor;

@property UIColor * tabBarBackgroundColor;
@property UIColor * tabBarItemColor;

@property UIColor * activeColor;
@property UIColor * inactiveColor;

@property UIColor * primaryTextColor;
@property UIColor * primaryTextHighlightColor;

@property UIColor * smallTextColor;

@property UIColor * primarySeparatorColor;

@property UIColor * primaryPlaceholderColor;

@property UIButton * primaryInactiveButton;
@property UIButton * primaryActiveButton;

@property UIButton * preferredBrokerButton;

+(id) sharedStyles;

-(UIColor *) retrieveEtradeColor;
-(UIColor *) retrieveRobinhoodColor;
-(UIColor *) retrieveSchwabColor;
-(UIColor *) retrieveScottradeColor;
-(UIColor *) retrieveFidelityColor;
-(UIColor *) retrieveTdColor;
-(UIColor *) retrieveOptionsHouseColor;

@end
