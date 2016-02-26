//
//  TTSDKPortfolioService.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/15/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTSDKAccountSummaryResult.h"
#import "TTSDKPortfolioAccount.h"

@interface TTSDKPortfolioService : NSObject



@property NSArray * accounts;

-(id) initWithAccounts:(NSArray *)accounts;
-(void) getSummaryForAccounts:(void (^)(void)) completionBlock;
-(void) getBalancesForAccounts:(void (^)(void)) completionBlock;
-(void) getQuotesForAccounts:(void (^)(void)) completionBlock;
-(NSArray *) positionsForAccounts;
-(NSArray *) filterPositionsByAccount:(TTSDKPortfolioAccount *)portfolioAccount;
-(NSNumber *) getTotalPositionsHeld;



@end
