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
@property TTSDKPortfolioAccount * selectedAccount;

-(id) initWithAccounts:(NSArray *)accounts;
-(void) getSummaryForAccounts:(void (^)(void)) completionBlock;
-(void) getSummaryForSelectedAccount:(void (^)(void)) completionBlock;
-(void) getBalancesForAccounts:(void (^)(void)) completionBlock;
-(void) getQuotesForAccounts:(void (^)(void)) completionBlock;
-(void) getQuoteForPosition:(TTSDKPosition *)position withCompletionBlock:(void (^)(TradeItResult *)) completionBlock;
-(NSArray *) positionsForAccounts;
-(NSArray *) filterPositionsByAccount:(TTSDKPortfolioAccount *)portfolioAccount;
-(void) retrieveInitialSelectedAccount;
-(void) selectAccount:(NSString *)accountNumber;


@end
