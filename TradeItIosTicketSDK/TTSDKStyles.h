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

@property UIColor * activeButtonColor;
@property UIColor * activeButtonHighlightColor;
@property UIColor * inactiveButtonColor;
@property UIColor * warningColor;
@property UIColor * lossColor;
@property UIColor * gainColor;

@property UIColor * pageBackgroundColor;
@property UIColor * navigationBarBackgroundColor;
@property UIColor * navigationBarItemColor;

+ (id)sharedStyles;

-(UIColor *) retrieveEtradeColor;
-(UIColor *) retrieveRobinhoodColor;
-(UIColor *) retrieveSchwabColor;
-(UIColor *) retrieveScottradeColor;
-(UIColor *) retrieveFidelityColor;
-(UIColor *) retrieveTdColor;
-(UIColor *) retrieveOptionsHouseColor;

@end
