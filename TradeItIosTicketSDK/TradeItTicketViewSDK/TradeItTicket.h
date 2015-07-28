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
#import "TicketSession.h"
#import "Keychain.h"

#import "BrokerSelectViewController.h"
#import "CalculatorViewController.h"

@interface TradeItTicket : NSObject

+(UIColor *) activeColor;
+(UIColor *) baseTextColor;
+(UIColor *) tradeItBlue;

+(NSAttributedString *) logoString;
+(NSAttributedString *) logoStringLite;

+(UIImage *)imageWithImage:(UIImage *)image scaledToWidth: (float) i_width withInset: (float) inset;

+(NSString *) splitCamelCase:(NSString *) str;

+(NSArray *) getAvailableBrokers: (TicketSession *) tradeSession;
+(NSString *) getBrokerDisplayString:(NSString *) value;
+(NSString *) getBrokerValueString:(NSString *) displayString;

+(NSArray *) getLinkedBrokersList;
+(void) addLinkedBroker:(NSString *)broker;
+(void) removeLinkedBroker:(NSString *)broker;

+(void) storeUsername: (NSString *) username andPassword: (NSString *) password forBroker: (NSString *) broker;
+(TradeItAuthenticationInfo *) getStoredAuthenticationForBroker: (NSString *) broker;

+(BOOL) hasTouchId;

+(void) showTicket:(TicketSession *) tradeSession;
+(void) returnToParentApp: (TicketSession *) tradeSession;
+(void) restartTicket:(TicketSession *) tradeSession;

@end
