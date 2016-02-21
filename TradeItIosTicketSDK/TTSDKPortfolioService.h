//
//  TTSDKPortfolioService.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/15/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTSDKAccountSummaryResult.h"

@interface TTSDKPortfolioService : NSObject

@property NSArray * accounts;

-(void) getSummaryForAccounts:(void (^)(void)) completionBlock;
-(void) getBalancesForAccounts:(void (^)(void)) completionBlock;

-(void) getAccountSummaryFromAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TTSDKAccountSummaryResult *)) completionBlock;
-(void) getAccountSummaryFromLinkedAccounts:(void (^)(TTSDKAccountSummaryResult *)) completionBlock;
-(void) getBalancesFromLinkedAccounts:(void (^)(NSArray *)) completionBlock;
-(void) getBalancesFromAllAccounts:(void (^)(NSArray *)) completionBlock;
-(id) initWithAccounts:(NSArray *)accounts;

@end
