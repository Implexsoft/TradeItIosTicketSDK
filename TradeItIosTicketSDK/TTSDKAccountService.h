//
//  TTSDKAccountService.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/15/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTSDKAccountSummaryResult.h"

@interface TTSDKAccountService : NSObject

- (void)getAccountSummaryFromAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TTSDKAccountSummaryResult *)) completionBlock;
- (void)getAccountSummaryFromLinkedAccounts:(void (^)(TTSDKAccountSummaryResult *)) completionBlock;

@end
