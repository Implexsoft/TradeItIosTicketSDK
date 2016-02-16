//
//  TTSDKPosition.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/14/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TradeItPosition.h"
#import "TradeItResult.h"

@interface TTSDKPosition : TradeItPosition

@property NSNumber * bid;
@property NSNumber * ask;
@property NSNumber * change;
@property NSNumber * changePct;
@property NSString * companyName;
@property NSNumber * totalValue;

-(id) initWithPosition:(TradeItPosition *)position;
-(void) getPositionData:(void (^)(TradeItResult *)) completionBlock;
-(BOOL) isDataPopulated;

@end
