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

@property NSNumber * change;
@property NSNumber * changePct;

-(void) getPositionData:(void (^)(TradeItResult *)) completionBlock;
-(BOOL) isDataPopulated;

@end
