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
#import "TradeItAuthenticationInfo.h"
#import "TradeItLinkedLogin.h"

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

@property TradeItLinkedLogin * currentLogin;

@property NSString * initialSymbol;
@property NSString * initialCompanyName;
@property NSString * initialAction;
@property double initialLastPrice;
@property NSNumber * initialPriceChangeDollar;
@property NSNumber * initialPriceChangePercentage;

@property (copy) void (^callback)(TradeItTicketControllerResult * result);
@property TradeItTicketControllerResult * resultContainer;

//@property (copy) void (^brokerSignUpCallback)(TradeItAuthControllerResult * result);

+ (id)globalController;
- (id)initWithApiKey:(NSString *)apiKey;
- (void)showTicket;
- (void)authenticate:(TradeItAuthenticationInfo *)authInfo withCompletionBlock:(void (^)(TradeItResult *)) completionBlock;

@end
