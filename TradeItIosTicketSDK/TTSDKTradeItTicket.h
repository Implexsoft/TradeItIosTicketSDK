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

@interface TTSDKTradeItTicket : NSObject

@property TradeItConnector * connector;

@property (nonatomic) NSArray * brokerList;

@property UIViewController * parentView;

@property NSString * errorTitle;
@property NSString * errorMessage;

@property BOOL brokerSignUpComplete;
@property BOOL debugMode;
@property BOOL portfolioMode;

@property NSArray * sessions;



@property (nonatomic) TTSDKTicketSession * currentSession;
@property (nonatomic, retain, getter=currentAccount) NSDictionary * currentAccount;
@property (nonatomic, retain, getter=allAccounts) NSArray * allAccounts;
@property (nonatomic, retain, getter=linkedAccounts) NSArray * linkedAccounts;












//@property NSDictionary * currentAccount;
@property TradeItAccountOverviewResult * currentAccountOverview;

@property (copy) void (^callback)(TradeItTicketControllerResult * result);
@property TradeItTicketControllerResult * resultContainer;

@property TradeItPreviewTradeRequest * previewRequest;

@property TTSDKPosition * position;
@property TradeItGetPositionsResult * currentPositionsResult;
//@property TradeItPlaceTradeRequest * placeTradeRequest;
//@property NSString * positionCompanyName;
@property (copy) void (^brokerSignUpCallback)(TradeItAuthControllerResult * result);




+(id) globalTicket;
-(void)showTicket;

// session
-(void)addSession:(TTSDKTicketSession *)session;
-(void)selectSession:(TTSDKTicketSession *)session andAccount:(NSDictionary *)account;

// account
-(void)addAccounts:(NSArray *)accounts withSession:(TTSDKTicketSession *)session;
-(void) saveAccountsToUserDefaults:(NSArray *)accounts;
-(void)unlinkAccounts;

// trading
-(void)switchSymbolToPosition:(TTSDKPosition *)position withAction:(NSString *)action;





-(NSString *)getBrokerDisplayString:(NSString *) value;
-(NSString *)getBrokerValueString:(NSString *) displayString;
-(NSArray *)getBrokerByValueString:(NSString *) valueString;
-(void)returnToParentApp;
-(void)createInitialPreviewRequest;

-(void)createInitialPositionWithSymbol:(NSString *)symbol andLastPrice:(NSNumber *)lastPrice;
-(void)retrievePositionsFromAccount:(NSDictionary *)account withCompletionBlock:(void (^)(TradeItResult *)) completionBlock;
-(void)retrieveAccountOverview:(NSString *)accountNumber withCompletionBlock:(void (^)(TradeItResult *)) completionBlock;

-(TTSDKTicketSession *)retrieveSessionByAccount:(NSDictionary *)account;

@end
