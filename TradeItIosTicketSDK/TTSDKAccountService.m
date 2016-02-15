//
//  TTSDKAccountService.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/15/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountService.h"
#import "TTSDKTicketController.h"



typedef void(^SummaryCompletionBlock)(TTSDKAccountSummaryResult *);

@interface TTSDKAccountService() {
    TTSDKTicketController * globalController;

    NSNumber * positionsCounter;
    NSMutableArray * accountPositionsResult;

    NSNumber * balancesCounter;
    NSMutableArray * accountBalancesResult;

    NSNumber * accountsTotal;
    NSTimer * summaryTimer;
    SummaryCompletionBlock returnBlock;
}

@end

@implementation TTSDKAccountService



-(id) init {
    if (self = [super init]) {
        globalController = [TTSDKTicketController globalController];
    }
    return self;
}

-(void) getAccountSummaryFromAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TTSDKAccountSummaryResult *)) completionBlock {
    TTSDKTicketSession * session = [globalController retrieveSessionByAccount: account];
    returnBlock = completionBlock;
    accountsTotal = @1;
    positionsCounter = @0;
    balancesCounter = @0;
    accountPositionsResult = [[NSMutableArray alloc] init];
    accountBalancesResult = [[NSMutableArray alloc] init];
    summaryTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkSingleAccountSummaryResults) userInfo:nil repeats:YES];

    [session getPositionsFromAccount:account withCompletionBlock:^(NSArray * positionsResult) {
        positionsCounter = [NSNumber numberWithInt: [positionsCounter intValue] + 1 ];
        [accountPositionsResult addObjectsFromArray: positionsResult];
    }];

    [session getOverviewFromAccount: account withCompletionBlock:^(TradeItAccountOverviewResult * overviewResult) {
        balancesCounter = [NSNumber numberWithInt: [balancesCounter intValue] + 1];
        if ([overviewResult isKindOfClass:TradeItAccountOverviewResult.class]) {
            [accountBalancesResult addObject: overviewResult];
        }
    }];
}

-(void) checkSingleAccountSummaryResults {
    BOOL positionsComplete = [positionsCounter isEqualToNumber: accountsTotal];
    BOOL balancesComplete = [balancesCounter isEqualToNumber: accountsTotal];

    if (positionsComplete && balancesComplete) {
        [summaryTimer invalidate];
        
        TTSDKAccountSummaryResult * summary = [[TTSDKAccountSummaryResult alloc] init];
        summary.positions = [accountPositionsResult copy];
        summary.balance = (TradeItAccountOverviewResult *)[accountBalancesResult firstObject];

        returnBlock(summary);
    }
}


-(void) getAccountSummaryFromLinkedAccounts:(void (^)(TTSDKAccountSummaryResult *)) completionBlock {
    NSArray * linkedAccounts = [globalController retrieveLinkedAccounts];

    returnBlock = completionBlock;
    accountPositionsResult = [[NSMutableArray alloc] init];
    accountBalancesResult = [[NSMutableArray alloc] init];
    accountsTotal = [NSNumber numberWithInteger: linkedAccounts.count];
    positionsCounter = @0;
    balancesCounter = @0;
    summaryTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkSummaryResults) userInfo:nil repeats:YES];

    for (NSDictionary * account in linkedAccounts) {
        TTSDKTicketSession * session = [globalController retrieveSessionByAccount: account];

        [session getPositionsFromAccount: account withCompletionBlock:^(NSArray * positions) {
            positionsCounter = [NSNumber numberWithInt: [positionsCounter intValue] + 1 ];
            [accountPositionsResult addObjectsFromArray: positions];
        }];

        [session getOverviewFromAccount: account withCompletionBlock:^(TradeItAccountOverviewResult * overviewResult) {
            balancesCounter = [NSNumber numberWithInt: [balancesCounter intValue] + 1];
            [accountBalancesResult addObject: overviewResult];
        }];
    }
}

-(void) checkSummaryResults {
    BOOL positionsComplete = [positionsCounter isEqualToNumber: accountsTotal];
    BOOL balancesComplete = [balancesCounter isEqualToNumber: accountsTotal];

    if (positionsComplete && balancesComplete) {
        [summaryTimer invalidate];

        TTSDKAccountSummaryResult * summary = [[TTSDKAccountSummaryResult alloc] init];
        summary.positions = [accountPositionsResult copy];
        summary.balances = [accountBalancesResult copy];

        returnBlock(summary);
    }
}



@end
