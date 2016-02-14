//
//  TTSDKTicketSession.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/11/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <TradeItIosTicketSDK/TradeItIosTicketSDK.h>
#import "TradeItSession.h"
#import "TradeItPreviewTradeRequest.h"
#import "TradeItPlaceTradeRequest.h"
#import "TradeItGetPositionsRequest.h"

@interface TTSDKTicketSession : TradeItSession <UIPickerViewDataSource, UIPickerViewDelegate>

@property NSArray * accounts;
@property NSDictionary * currentAccount;
@property NSArray * positions;
@property TradeItLinkedLogin * login;
@property NSString * broker;
@property BOOL isAuthenticated;
@property TradeItPreviewTradeRequest * previewRequest;
@property TradeItPlaceTradeRequest * tradeRequest;
@property TradeItGetPositionsRequest * positionsRequest;

- (id) initWithConnector: (TradeItConnector *) connector andLinkedLogin:(TradeItLinkedLogin *)linkedLogin andBroker:(NSString *)broker;
- (void) authenticateFromViewController:(UIViewController *)viewController withCompletionBlock:(void (^)(TradeItResult *))completionBlock;
- (void) createPreviewRequest;
- (void) createPreviewRequestWithSymbol:(NSString *)symbol andAction:(NSString *)action andQuantity:(NSNumber *)quantity;
- (void) previewTrade:(void (^)(TradeItResult *)) completionBlock;
- (void) placeTrade:(void (^)(TradeItResult *)) completionBlock;

- (void) getPositionsFromAccount:(NSDictionary *)account withCompletionBlock:(void (^)(NSArray *))completionBlock;

@end
