//
//  TTSDKTicketController.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/3/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TradeItTicketControllerResult.h"
#import "TradeItResult.h"
#import "TradeItConnector.h"
#import "TradeItAuthenticationInfo.h"
#import "TradeItAuthControllerResult.h"
#import "TradeItLinkedLogin.h"
#import "TradeItPreviewTradeOrderDetails.h"
#import "TradeItPreviewTradeRequest.h"
#import "TradeItPreviewTradeResult.h"
#import "TradeItPosition.h"

@interface TTSDKTicketController : NSObject

@property NSString * apiKey;

@property UIViewController * parentView;
@property NSString * errorTitle;
@property NSString * errorMessage;
@property (copy) void (^refreshLastPrice)(NSString * symbol, void(^callback)(double lastPrice));
@property (copy) void (^refreshQuote)(NSString * symbol, void(^callback)(double lastPrice, double priceChangeDollar, double priceChangePercentage, NSString * quoteUpdateTime));

@property NSArray * brokerList;
@property BOOL brokerSignUpComplete;
@property BOOL debugMode;
@property BOOL portfolioMode;
@property NSString * currentBroker;
@property NSArray * accounts;

@property TradeItLinkedLogin * currentLogin;
@property TradeItConnector * connector;
@property NSDictionary * currentAccount;

@property (copy) void (^callback)(TradeItTicketControllerResult * result);
@property TradeItTicketControllerResult * resultContainer;

@property TradeItPreviewTradeRequest * tradeRequest;
@property TradeItPosition * position;
@property NSString * positionCompanyName;

@property (copy) void (^brokerSignUpCallback)(TradeItAuthControllerResult * result);

+ (id)globalController;
- (id)initWithApiKey:(NSString *)apiKey;
- (void)showTicket;
- (void)authenticate:(TradeItAuthenticationInfo *)authInfo withCompletionBlock:(void (^)(TradeItResult *)) completionBlock;
- (void)answerSecurityQuestion:(NSString *)answer withCompletionBlock:(void (^)(TradeItResult *)) completionBlock;
- (void)addAccounts: (NSArray *)accounts;
- (void)selectAccount:(NSDictionary *) account;
- (void)unlinkAccounts;
- (NSArray *)getLinkedLogins;
- (NSString *)getBrokerDisplayString:(NSString *) value;
- (NSString *)getBrokerValueString:(NSString *) displayString;
- (void)previewTrade:(void (^)(TradeItResult *)) completionBlock;
- (void)returnToParentApp;
- (void)createInitialTradeRequest;
-(void) createInitialTradeRequestWithSymbol:(NSString *)symbol andAction:(NSString *)action andQuantity:(NSNumber *)quantity;
- (void)createInitialPositionWithSymbol:(NSString *)symbol andLastPrice:(NSNumber *)lastPrice;

@end
