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
#import "TTSDKOrderViewController.h"
#import "TTSDKLinkPromptViewController.h"

@interface TTSDKTradeItTicket : NSObject

+(NSArray *) getAvailableBrokers: (TTSDKTicketSession *) tradeSession;
+(NSString *) getBrokerDisplayString:(NSString *) value;
+(NSString *) getBrokerValueString:(NSString *) displayString;

+(NSArray *) getLinkedBrokersList;
+(void) addLinkedBroker:(NSString *)broker;
+(void) removeLinkedBroker:(NSString *)broker;

+(void) storeUsername: (NSString *) username andPassword: (NSString *) password forBroker: (NSString *) broker;
+(TradeItAuthenticationInfo *) getStoredAuthenticationForBroker: (NSString *) broker;

+(void) setInitialScreenPreference: (NSString *) storyboardId;
+(NSString *) getInitialScreenPreference;

+(BOOL) hasTouchId;

+(void) showTicket:(TTSDKTicketSession *) tradeSession;
+(void) returnToParentApp: (TTSDKTicketSession *) tradeSession;
+(void) restartTicket:(TTSDKTicketSession *) tradeSession;

@end
