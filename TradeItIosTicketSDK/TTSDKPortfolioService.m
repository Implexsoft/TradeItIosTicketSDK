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

// naming it 'highlighted' to distinguish from last account selected for trading
static NSString * kSelectedAccountKey = @"TRADEIT_LAST_HIGHLIGHTED_ACCOUNT";

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

-(void) retrieveInitialSelectedAccount {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * lastSelected = [defaults objectForKey: kSelectedAccountKey];

    if (!lastSelected) {
        lastSelected = [(TTSDKPortfolioAccount *)[self.accounts objectAtIndex:0] accountNumber];
    }

    [self selectAccount: lastSelected];
}

-(void) selectAccount:(NSString *)accountNumber {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

    TTSDKPortfolioAccount * selectedAccount;

    for (TTSDKPortfolioAccount * account in self.accounts) {
        if ([account.accountNumber isEqualToString: accountNumber]) {
            selectedAccount = account;
            break;
        }
    }

    if (!selectedAccount) {
        if (self.accounts && [self.accounts count]) {
            selectedAccount = [self.accounts firstObject];
        } else {
            return;
        }
    }

    self.selectedAccount = selectedAccount;

    [defaults setObject:selectedAccount.accountNumber forKey:kSelectedAccountKey];
    [defaults synchronize];
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

-(void) getQuoteForPosition:(TTSDKPosition *)position withCompletionBlock:(void (^)(TradeItResult *)) completionBlock {
    TradeItMarketDataService * marketService = [[TradeItMarketDataService alloc] initWithSession: globalTicket.currentSession];
    TradeItQuotesRequest * quoteRequest = [[TradeItQuotesRequest alloc] initWithSymbol:position.symbol];

    [marketService getQuoteData:quoteRequest withCompletionBlock:^(TradeItResult * res) {
        if (completionBlock) {
            completionBlock(res);
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

-(void) getSummaryForSelectedAccount:(void (^)(void)) completionBlock {
    if (!self.selectedAccount) {
        completionBlock();
        return;
    }

    [self.selectedAccount retrieveAccountSummaryWithCompletionBlock: ^(void) {
        completionBlock();
    }];
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
