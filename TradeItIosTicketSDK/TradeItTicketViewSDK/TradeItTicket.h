//
//  TradeItTicket.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/22/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TradeItTicket : NSObject

+(UIColor *) activeColor;
+(UIColor *) baseTextColor;
+(UIColor *) tradeItBlue;

+(NSAttributedString *) logoString;
+(NSAttributedString *) logoStringLite;

+(NSString *) getImagePathFromBundle: (NSString *) imageName;

+(NSString *) splitCamelCase:(NSString *) str;

@end
