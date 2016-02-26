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

-(NSArray *) filterPositionsByAccount:(TTSDKPortfolioAccount *)portfolioAccount {
    NSArray * positions = portfolioAccount.positions;

    return positions;
}

-(void) getQuotesForAccounts:(void (^)(void)) completionBlock {
    TradeItMarketDataService * marketService = [[TradeItMarketDataService alloc] initWithSession: globalTicket.currentSession];

    NSArray * symbols = [[NSArray alloc] init];

    NSCharacterSet * digits = [NSCharacterSet decimalDigitCharacterSet];
    for (TTSDKPortfolioAccount *portfolioAccount in self.accounts) {
        for (TTSDKPosition *position in portfolioAccount.positions) {
            if ([position.symbol rangeOfCharacterFromSet:digits].location == NSNotFound) {
                NSArray * symArr = @[position.symbol];
                symbols = [symbols arrayByAddingObjectsFromArray:symArr];
            }
        }
    }

    // Note: I can't find a better/faster way to do this
    TradeItQuotesRequest * quoteRequest = [[TradeItQuotesRequest alloc] initWithSymbols:symbols];
    [marketService getQuoteData:quoteRequest withCompletionBlock:^(TradeItResult * res) {
        if ([res isKindOfClass:TradeItQuotesResult.class]) {
            TradeItQuotesResult * result = (TradeItQuotesResult *)res;

            for (NSDictionary *quoteData in result.quotes) {
                for (TTSDKPortfolioAccount *portfolioAccount in self.accounts) {
                    for (TTSDKPosition * position in portfolioAccount.positions) {
                        if ([position.symbol isEqualToString:[quoteData valueForKey:@"symbol"]]) {
                            position.quote = [[TradeItQuote alloc] initWithQuoteData:quoteData];
                        }
                    }
                }
            }
        }

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

-(NSNumber *) getTotalPositionsHeld {
    NSNumber * count = @0;

    if (self.accounts.count) {
        for (TTSDKPortfolioAccount *portfolioAccount in self.accounts) {
            for (TTSDKPosition *position in portfolioAccount.positions) {

                NSLog(@"cycling through each account position. symbol: %@ quantity: %@", position.symbol, [position.quantity stringValue]);
                count = [NSNumber numberWithInt: [count intValue] + [position.quantity intValue]];
                NSLog(@"count is now %@", [count stringValue]);
            }
        }
    }

    return count;
}



@end
