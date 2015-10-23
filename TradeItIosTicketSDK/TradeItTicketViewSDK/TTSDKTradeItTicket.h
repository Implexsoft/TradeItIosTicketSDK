//
//  TradeItTicket.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/22/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "TTSDKTicketSession.h"
#import "TTSDKKeychain.h"

#import "TTSDKBrokerSelectViewController.h"
#import "TTSDKCalculatorViewController.h"
#import "TTSDKAdvCalculatorViewController.h"

@interface TTSDKTradeItTicket : NSObject

+(UIColor *) activeColor;
+(UIColor *) baseTextColor;
+(UIColor *) tradeItBlue;

+(NSAttributedString *) logoString;
+(NSAttributedString *) logoStringLite;

+(UIImage *)imageWithImage:(UIImage *)image scaledToWidth: (float) i_width withInset: (float) inset;

+(NSString *) splitCamelCase:(NSString *) str;

+(NSArray *) getAvailableBrokers: (TTSDKTicketSession *) tradeSession;
+(NSString *) getBrokerDisplayString:(NSString *) value;
+(NSString *) getBrokerValueString:(NSString *) displayString;

+(NSArray *) getLinkedBrokersList;
+(void) addLinkedBroker:(NSString *)broker;
+(void) removeLinkedBroker:(NSString *)broker;

+(void) storeUsername: (NSString *) username andPassword: (NSString *) password forBroker: (NSString *) broker;
+(TradeItAuthenticationInfo *) getStoredAuthenticationForBroker: (NSString *) broker;

+(void) setCalcScreenPreferance: (NSString *) storyboardId;
+(NSString *) getCalcScreenPreferance;

+(BOOL) hasTouchId;

+(void) showTicket:(TTSDKTicketSession *) tradeSession;
+(void) returnToParentApp: (TTSDKTicketSession *) tradeSession;
+(void) restartTicket:(TTSDKTicketSession *) tradeSession;

+(BOOL) containsString: (NSString *) base searchString: (NSString *) searchString;

@end
