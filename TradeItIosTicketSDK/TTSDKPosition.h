//
//  TTSDKPosition.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/14/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TradeItPosition.h"
#import "TradeItResult.h"
#import "TradeItQuote.h"

@interface TTSDKPosition : TradeItPosition


@property NSNumber * change;
@property NSNumber * changePct;
@property NSString * companyName;
@property NSNumber * totalValue;
@property TradeItQuote * quote;

-(id) initWithPosition:(TradeItPosition *)position;


@end
