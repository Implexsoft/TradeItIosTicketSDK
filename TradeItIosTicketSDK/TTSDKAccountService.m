//
//  TTSDKAccountService.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/15/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAccountService.h"
#import "TTSDKTradeItTicket.h"



typedef void(^SummaryCompletionBlock)(TTSDKAccountSummaryResult *);
typedef void(^BalancesCompletionBlock)(NSArray *);

@interface TTSDKAccountService() {
    TTSDKTradeItTicket * globalTicket;

    NSNumber * positionsCounter;
    NSMutableArray * accountPositionsResult;

    NSNumber * balancesCounter;
    NSMutableArray * accountBalancesResult;

    NSNumber * accountsTotal;
    NSTimer * summaryTimer;
    SummaryCompletionBlock summaryBlock;

    NSTimer * balancesTimer;
    BalancesCompletionBlock balancesBlock;
    
}

@end

@implementation TTSDKAccountService



-(id) init {
    if (self = [super init]) {
        globalTicket = [TTSDKTradeItTicket globalTicket];
    }
    return self;
}

-(void) getAccountSummaryFromAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TTSDKAccountSummaryResult *)) completionBlock {
    TTSDKTicketSession * session = [globalTicket retrieveSessionByAccount: account];
    summaryBlock = completionBlock;
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

        summaryBlock(summary);
    }
}

-(void) getAccountSummaryFromLinkedAccounts:(void (^)(TTSDKAccountSummaryResult *)) completionBlock {
    NSArray * linkedAccounts = globalTicket.linkedAccounts;

    summaryBlock = completionBlock;
    accountPositionsResult = [[NSMutableArray alloc] init];
    accountBalancesResult = [[NSMutableArray alloc] init];
    accountsTotal = [NSNumber numberWithInteger: linkedAccounts.count];
    positionsCounter = @0;
    balancesCounter = @0;
    summaryTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkSummaryResults) userInfo:nil repeats:YES];

    for (NSDictionary * account in linkedAccounts) {
        TTSDKTicketSession * session = [globalTicket retrieveSessionByAccount: account];

        [session getPositionsFromAccount: account withCompletionBlock:^(NSArray * positionsResult) {
            positionsCounter = [NSNumber numberWithInt: [positionsCounter intValue] + 1 ];
            [accountPositionsResult addObjectsFromArray: positionsResult];
        }];

        [session getOverviewFromAccount: account withCompletionBlock:^(TradeItAccountOverviewResult * overviewResult) {
            balancesCounter = [NSNumber numberWithInt: [balancesCounter intValue] + 1];
            NSMutableDictionary * overviewDict = [NSMutableDictionary dictionaryWithDictionary:account];
            [overviewDict setObject:overviewResult forKey:@"overview"];
            [accountBalancesResult addObject: overviewDict];
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

        summaryBlock(summary);
    }
}

-(void) getBalancesFromLinkedAccounts:(void (^)(NSArray *)) completionBlock {
    NSArray * linkedAccounts = globalTicket.linkedAccounts;
    [self getBalancesFromAccounts:linkedAccounts withCompletionBlock:completionBlock];
}

-(void) getBalancesFromAllAccounts:(void (^)(NSArray *)) completionBlock {
    NSArray * allAccounts = globalTicket.linkedAccounts;
    [self getBalancesFromAccounts:allAccounts withCompletionBlock:completionBlock];
}

// private wrapper
-(void) getBalancesFromAccounts:(NSArray *)accountsList withCompletionBlock:(void (^)(NSArray *)) completionBlock {
    balancesBlock = completionBlock;
    accountBalancesResult = [[NSMutableArray alloc] init];
    accountsTotal = [NSNumber numberWithInteger: accountsList.count];
    balancesCounter = @0;
    summaryTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkBalancesResults) userInfo:nil repeats:YES];

    for (NSDictionary * account in accountsList) {
        TTSDKTicketSession * session = [globalTicket retrieveSessionByAccount: account];

        [session getOverviewFromAccount: account withCompletionBlock:^(TradeItAccountOverviewResult * overviewResult) {
            balancesCounter = [NSNumber numberWithInt: [balancesCounter intValue] + 1];
            NSMutableDictionary * overviewDict = [NSMutableDictionary dictionaryWithDictionary:account];
            [overviewDict setObject:overviewResult forKey:@"overview"];
            [accountBalancesResult addObject: overviewDict];
        }];
    }
}

-(void) checkBalancesResults {
    BOOL balancesComplete = [balancesCounter isEqualToNumber: accountsTotal];

    if (balancesComplete) {
        [balancesTimer invalidate];
        balancesBlock([accountBalancesResult copy]);
    }
}


@end
