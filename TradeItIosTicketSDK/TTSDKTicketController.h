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
#import "TradeItPlaceTradeRequest.h"
#import "TradeItPlaceTradeResult.h"
#import "TradeItPosition.h"
#import "TradeItAccountOverviewResult.h"
#import "TradeItGetPositionsResult.h"
#import "TTSDKTicketSession.h"
#import "TTSDKPosition.h"

@interface TTSDKTicketController : NSObject

@property NSString * apiKey;

@property UIViewController * parentView;
@property NSString * errorTitle;
@property NSString * errorMessage;
@property (copy) void (^refreshLastPrice)(NSString * symbol, void(^callback)(double lastPrice));
@property (copy) void (^refreshQuote)(NSString * symbol, void(^callback)(double lastPrice, double priceChangeDollar, double priceChangePercentage, NSString * quoteUpdateTime));

@property BOOL brokerSignUpComplete;
@property BOOL debugMode;
@property BOOL portfolioMode;



@property NSArray * sessions;
@property TTSDKTicketSession * currentSession;





@property NSArray * brokerList;

@property NSArray * linkedLogins;

@property TradeItConnector * connector;
//@property NSDictionary * currentAccount;
@property TradeItAccountOverviewResult * currentAccountOverview;

@property (copy) void (^callback)(TradeItTicketControllerResult * result);
@property TradeItTicketControllerResult * resultContainer;

@property TradeItPreviewTradeRequest * initialPreviewRequest;
@property TTSDKPosition * position;
@property TradeItGetPositionsResult * currentPositionsResult;

//@property TradeItPlaceTradeRequest * placeTradeRequest;

@property NSString * positionCompanyName;

@property (copy) void (^brokerSignUpCallback)(TradeItAuthControllerResult * result);

+ (id)globalController;
- (id)initWithApiKey:(NSString *)apiKey;
- (void)showTicket;
- (NSArray *)retrieveAccounts;
- (void)addAccounts:(NSArray *)accounts withSession:(TTSDKTicketSession *)session;
- (void)selectAccount:(NSDictionary *)account;
- (NSArray *)retrieveLinkedAccounts;
- (void)updateAccounts:(NSArray *)accounts;
- (void)unlinkAccounts;
- (void)switchAccountsFromViewController:(UIViewController *)viewController toAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TradeItResult *)) completionBlock;

- (void)addSession:(TTSDKTicketSession *)session;
- (void)selectSession:(TTSDKTicketSession *)session andAccount:(NSDictionary *)account;

- (NSArray *)retrieveLinkedLogins;
- (NSString *)getBrokerDisplayString:(NSString *) value;
- (NSString *)getBrokerValueString:(NSString *) displayString;
- (NSArray *)getBrokerByValueString:(NSString *) valueString;
- (void)returnToParentApp;
- (void)createInitialPreviewRequest;
- (void)createInitialPreviewRequestWithSymbol:(NSString *)symbol andAction:(NSString *)action andQuantity:(NSNumber *)quantity;
- (void)passInitialPreviewRequestToSession;
- (void)createInitialPositionWithSymbol:(NSString *)symbol andLastPrice:(NSNumber *)lastPrice;
- (void)retrievePositionsFromAccounts:(NSArray *)accounts withCompletionBlock:(void (^)(NSArray *)) completionBlock;
- (void)retrievePositionsFromAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TradeItResult *)) completionBlock;
- (void)retrieveAccountOverview:(NSString *)accountNumber withCompletionBlock:(void (^)(TradeItResult *)) completionBlock;

- (void)retrievePortfolioDataFromAllAccounts:(void (^)(NSArray *)) completionBlock;

@end
