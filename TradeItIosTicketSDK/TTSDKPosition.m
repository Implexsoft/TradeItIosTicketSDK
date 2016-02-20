//
//  TTSDKPosition.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/14/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPosition.h"
#import "TradeItMarketDataService.h"
#import "TTSDKTradeItTicket.h"
#import "TradeItQuotesResult.h"
#import "TradeItQuote.h"

@implementation TTSDKPosition



-(id) initWithPosition:(TradeItPosition *)position {
    if (self = [super init]) {
        self.symbol = position.symbol;
        self.symbolClass = position.symbolClass;
        self.holdingType = position.holdingType;
        self.costbasis = position.costbasis;
        self.lastPrice = position.lastPrice;
        self.quantity = position.quantity;
        self.todayGainLossDollar = position.todayGainLossDollar;
        self.todayGainLossPercentage = position.todayGainLossPercentage;
        self.totalGainLossDollar = position.totalGainLossDollar;
        self.totalGainLossPercentage = position.totalGainLossPercentage;
    }
    return self;
}

-(void) getPositionData:(void (^)(TradeItQuote *)) completionBlock {
    TTSDKTradeItTicket * globalTicket = [TTSDKTradeItTicket globalTicket];

    if (globalTicket.currentSession) {
        TTSDKTicketSession * session = globalTicket.currentSession;
        TradeItMarketDataService * marketService = [[TradeItMarketDataService alloc] initWithSession: session];

        TradeItQuotesRequest * request = [[TradeItQuotesRequest alloc] initWithSymbol: self.symbol];

        [marketService getQuoteData:request withCompletionBlock:^(TradeItResult * res) {
            if ([res isKindOfClass:TradeItQuotesResult.class]) {
                TradeItQuotesResult * result = (TradeItQuotesResult *)res;
                TradeItQuote * quote = [[TradeItQuote alloc] initWithQuoteData: (NSDictionary *)[result.quotes objectAtIndex: 0]];

                if (quote) {
                    self.ask = quote.askPrice;
                    self.bid = quote.bidPrice;
                    self.change = quote.change;
                    self.changePct = quote.pctChange;
                    self.lastPrice = quote.lastPrice;
                }

                if (completionBlock) {
                    completionBlock(quote);
                }
            } else {
                if (completionBlock) {
                    completionBlock(nil);
                }
            }
        }];
    }
}



@end
