//
//  TTSDKPortfolioService.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/15/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioService.h"
#import "TTSDKTradeItTicket.h"
#import "TradeItMarketDataService.h"
#import "TradeItQuotesResult.h"

typedef void(^DataCompletionBlock)(void);

typedef void(^SummaryCompletionBlock)(TTSDKAccountSummaryResult *);
typedef void(^BalancesCompletionBlock)(NSArray *);

@interface TTSDKPortfolioService() {
    TTSDKTradeItTicket * globalTicket;
    BalancesCompletionBlock balancesBlock;
    NSTimer * dataTimer;
    DataCompletionBlock dataBlock;
}

@end

@implementation TTSDKPortfolioService


-(id) init {
    if (self = [super init]) {
        globalTicket = [TTSDKTradeItTicket globalTicket];
    }
    return self;
}

-(id) initWithAccounts:(NSArray *)accounts {
    if (self = [super init]) {
        globalTicket = [TTSDKTradeItTicket globalTicket];

        NSMutableArray * portfolioAccounts = [[NSMutableArray alloc] init];
        for (NSDictionary *accountData in accounts) {
            TTSDKPortfolioAccount * portfolioAccount = [[TTSDKPortfolioAccount alloc] initWithAccountData: accountData];
            [portfolioAccounts addObject:portfolioAccount];
        }

        self.accounts = portfolioAccounts;
    }

    return self;
}

-(NSArray *) positionsForAccounts {
    NSMutableArray * positions = [[NSMutableArray alloc] init];

    if (self.accounts) {
        for (TTSDKPortfolioAccount *account in self.accounts) {
            [positions addObjectsFromArray: account.positions];
        }
    }

    return positions;
}

-(void) getQuotesForAccounts:(void (^)(void)) completionBlock {
    TradeItMarketDataService * marketService = [[TradeItMarketDataService alloc] initWithSession: globalTicket.currentSession];

    NSArray * symbols = [[NSArray alloc] init];

    for (TTSDKPortfolioAccount *portfolioAccount in self.accounts) {
        for (TTSDKPosition *position in portfolioAccount.positions) {
            NSArray * symArr = @[position.symbol];
            symbols = [symbols arrayByAddingObjectsFromArray:symArr];
        }
    }

    TradeItQuotesRequest * quoteRequest = [[TradeItQuotesRequest alloc] initWithSymbols:symbols];
    [marketService getQuoteData:quoteRequest withCompletionBlock:^(TradeItResult * res) {

    }];
}

-(void) getSummaryForAccounts:(void (^)(void)) completionBlock {
    if (!self.accounts) {
        completionBlock();
        return;
    }

    dataTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkSummary) userInfo:nil repeats:YES];
    dataBlock = completionBlock;

    for (TTSDKPortfolioAccount * portfolioAccount in self.accounts) {
        [portfolioAccount retrieveAccountSummary];
    }
}

-(void) checkSummary {
    BOOL complete = YES;

    for (TTSDKPortfolioAccount * portfolioAccount in self.accounts) {
        if (![portfolioAccount dataComplete] && ![portfolioAccount needsAuthentication]) {
            complete = NO;
        }
    }

    if (complete) {
        [dataTimer invalidate];
        dataBlock();
    }
}

-(void) getBalancesForAccounts:(void (^)(void)) completionBlock {
    if (!self.accounts) {
        completionBlock();
        return;
    }

    dataTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkSummary) userInfo:nil repeats:YES];
    dataBlock = completionBlock;

    for (TTSDKPortfolioAccount * portfolioAccount in self.accounts) {
        portfolioAccount.positionsComplete = YES; // bypasses position retrieval
        [portfolioAccount retrieveBalance];
    }
}



@end
