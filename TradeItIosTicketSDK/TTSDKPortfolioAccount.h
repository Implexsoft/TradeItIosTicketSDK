//
//  TTSDKAccount.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/21/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TradeItAccountOverviewResult.h"

@interface TTSDKPortfolioAccount : NSObject

@property NSString * userId;
@property NSString * accountNumber;
@property NSString * displayTitle;
@property NSString * name;
@property NSString * broker;
@property BOOL active;
@property BOOL lastSelected;
@property BOOL tradable;
@property BOOL balanceComplete;
@property BOOL positionsComplete;
@property NSArray * positions;
@property TradeItAccountOverviewResult * balance;

-(BOOL) dataComplete;
-(id) initWithAccountData:(NSDictionary *)data;
-(void) retrieveAccountSummary;
-(void) retrieveBalance;

-(NSDictionary *) accountData;

@end
