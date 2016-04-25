//
//  TTSDKAccount.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/21/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioAccount.h"
#import "TTSDKTradeItTicket.h"

@interface TTSDKPortfolioAccount() {
    TTSDKTradeItTicket * globalTicket;
    TradeItAccountOverviewResult * balanceCache;
    NSArray * positionCache;
    NSDate * lastLoadTime;
}

@end

@implementation TTSDKPortfolioAccount

static double kLoadInterval = -30.0f;

-(id) initWithAccountData:(NSDictionary *)data {
    if (self = [super init]) {
        self.userId = [data valueForKey: @"UserId"];
        self.accountNumber = [data valueForKey: @"accountNumber"];
        self.displayTitle = [data valueForKey: @"displayTitle"];
        self.name = [data valueForKey: @"name"];
        self.active = [[data valueForKey: @"active"] boolValue];
        self.tradable = [[data valueForKey: @"tradable"] boolValue];
        self.broker = [data valueForKey: @"broker"];

        globalTicket = [TTSDKTradeItTicket globalTicket];
    }
    return self;
}

-(NSDictionary *) accountData {
    NSMutableDictionary * account = [[NSMutableDictionary alloc] init];

    [account setObject:self.userId forKey:@"UserId"];
    [account setObject:self.accountNumber forKey:@"accountNumber"];
    [account setObject:self.broker forKey:@"broker"];
    [account setObject:[NSNumber numberWithBool: self.active] forKey:@"active"];
    [account setObject:[NSNumber numberWithBool: self.tradable] forKey:@"tradable"];
    [account setObject:self.displayTitle forKey:@"displayTitle"];
    [account setObject:self.name forKey:@"name"];

    return [account copy];
}

-(BOOL) dataComplete {
    return self.balanceComplete && self.positionsComplete;
}

-(void) retrieveAccountSummary {
    [self retrieveAccountSummaryWithCompletionBlock:nil];
}

-(void) retrieveAccountSummaryWithCompletionBlock:(void (^)(void)) completionBlock {
    NSDictionary * accountData = [self accountData];
    TTSDKTicketSession * session = [globalTicket retrieveSessionByAccount: accountData];

    if (!session.isAuthenticated) {
        // If the authentication completed, but was not successful, set to complete
        if (session.needsManualAuthentication) {
            self.balanceComplete = YES;
            self.positionsComplete = YES;
            self.needsAuthentication = YES;
        } else {
            [self performSelector:@selector(retrieveAccountSummaryWithCompletionBlock:) withObject:completionBlock afterDelay:0.25];
        }

        return;
    } else {
        self.needsAuthentication = NO;
    }

    BOOL load;
    if (!lastLoadTime) {
        load = YES;
        lastLoadTime = [NSDate date];
    } else {
        NSDate * currentDate = [NSDate date];
        NSTimeInterval elapsed = [currentDate timeIntervalSinceDate: lastLoadTime];

        if (elapsed <= kLoadInterval) {
            load = YES;
        } else {
            load = NO;
        }

        lastLoadTime = currentDate;
    }

    if (load) {
        [session getOverviewFromAccount: accountData withCompletionBlock:^(TradeItAccountOverviewResult * overview) {
            self.balanceComplete = YES;
            
            if (overview != nil) {
                self.balance = overview;
            } else {
                self.balance = [[TradeItAccountOverviewResult alloc] init];
            }

            balanceCache = self.balance;

            if (self.positionsComplete && completionBlock != nil) {
                completionBlock();
            }
        }];

        [session getPositionsFromAccount: accountData withCompletionBlock:^(NSArray * positions) {
            self.positionsComplete = YES;
            
            if (positions != nil) {
                self.positions = positions;
            } else {
                self.positions = [[NSArray alloc] init];
            }

            positionCache = self.positions;

            if (self.balanceComplete && completionBlock != nil) {
                completionBlock();
            }
        }];
    } else {
        self.balance = balanceCache;
        self.positions = positionCache;

        if (completionBlock != nil) {
            completionBlock();
        }
    }

}

-(void) retrieveBalance {
    NSDictionary * accountData = [self accountData];
    TTSDKTicketSession * session = [globalTicket retrieveSessionByAccount: accountData];

    [session getOverviewFromAccount: accountData withCompletionBlock:^(TradeItAccountOverviewResult * overview) {
        self.balanceComplete = YES;

        if (overview != nil) {
            self.balance = overview;
        } else {
            self.balance = [[TradeItAccountOverviewResult alloc] init];
        }
    }];
}



@end
