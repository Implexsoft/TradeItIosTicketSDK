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
#import "TradeItTradeService.h"
#import "TradeItPositionService.h"
#import "TradeItBalanceService.h"
#import "TradeItAccountOverviewResult.h"

@interface TTSDKTicketSession : TradeItSession <UIPickerViewDataSource, UIPickerViewDelegate>

@property NSArray * positions;
@property TradeItLinkedLogin * login;
@property NSString * broker;
@property BOOL isAuthenticated;
@property BOOL needsAuthentication; // needs to be authenticated
@property BOOL needsManualAuthentication; // needs the user to re-link
@property BOOL authenticating;

@property TradeItPlaceTradeRequest * tradeRequest;
@property TradeItGetPositionsRequest * positionsRequest;

- (id) initWithConnector: (TradeItConnector *) connector andLinkedLogin:(TradeItLinkedLogin *)linkedLogin andBroker:(NSString *)broker;
- (void) authenticateFromViewController:(UIViewController *)viewController withCompletionBlock:(void (^)(TradeItResult *))completionBlock;

- (void) previewTrade:(TradeItPreviewTradeRequest *)previewRequest withCompletionBlock:(void (^)(TradeItResult *)) completionBlock;
- (void) placeTrade:(void (^)(TradeItResult *)) completionBlock;

- (void) getPositionsFromAccount:(NSDictionary *)account withCompletionBlock:(void (^)(NSArray *))completionBlock;
- (void) getOverviewFromAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TradeItAccountOverviewResult *)) completionBlock;

@end
