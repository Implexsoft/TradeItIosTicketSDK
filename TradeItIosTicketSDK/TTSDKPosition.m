//
//  TTSDKPosition.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/14/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPosition.h"
#import "TradeItMarketDataService.h"
#import "TTSDKTicketController.h"
#import "TradeItQuoteResult.h"

@interface TTSDKPosition() {
}

@end

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

-(void) getPositionData:(void (^)(TradeItResult *)) completionBlock {
    TTSDKTicketController * globalController = [TTSDKTicketController globalController];

    if (globalController.currentSession) {
        TTSDKTicketSession * session = globalController.currentSession;
        TradeItMarketDataService * marketService = [[TradeItMarketDataService alloc] initWithSession: session];
        TradeItQuoteRequest * request = [[TradeItQuoteRequest alloc] initWithSymbol: self.symbol];

        [marketService getQuote:request withCompletionBlock:^(TradeItResult * res) {
            if ([res isKindOfClass:TradeItQuoteResult.class]) {
                TradeItQuoteResult * result = (TradeItQuoteResult *)res;

                self.symbol = result.symbol;
                self.lastPrice = result.lastPrice;
                self.change = result.change;
                self.changePct = result.pctChange;
                self.bid = result.bidPrice;
                self.ask = result.askPrice;

                if (completionBlock) {
                    completionBlock(res);
                }
            } else {
                if (completionBlock) {
                    completionBlock(nil);
                }
            }
        }];
    }
}

-(BOOL) isDataPopulated {
    BOOL populated = YES;

    if (!self.lastPrice) {
        populated = NO;
    }

    if (!self.quantity && ![self.quantity isEqualToNumber:@0]) {
        populated = NO;
    }

    return populated;
}

@end
