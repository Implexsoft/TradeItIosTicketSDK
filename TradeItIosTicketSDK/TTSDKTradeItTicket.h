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



// properties
@property TradeItConnector * connector;
@property (nonatomic) NSArray * brokerList;
@property UIViewController * parentView;
@property NSString * errorTitle;
@property NSString * errorMessage;
@property BOOL brokerSignUpComplete;
@property BOOL debugMode;
@property BOOL portfolioMode;
@property BOOL authMode;

@property NSArray * sessions;
@property (nonatomic) TTSDKTicketSession * currentSession;
@property (nonatomic) NSDictionary * currentAccount;
@property (nonatomic, retain, getter=allAccounts) NSArray * allAccounts;
@property (nonatomic, retain, getter=linkedAccounts) NSArray * linkedAccounts;
@property (copy) void (^callback)(TradeItTicketControllerResult * result);
@property TradeItTicketControllerResult * resultContainer;
@property TradeItPreviewTradeRequest * previewRequest;
@property TradeItQuote * quote;



@property (copy) void (^brokerSignUpCallback)(TradeItAuthControllerResult * result);

// initialization
+(id) globalTicket;
-(void) launchAuthFlow;
-(void) launchTradeOrPortfolioFlow;

// authentication
-(void) addSession:(TTSDKTicketSession *)session;
-(void) selectCurrentSession:(TTSDKTicketSession *)session andAccount:(NSDictionary *)account;
-(TTSDKTicketSession *)retrieveSessionByAccount:(NSDictionary *)account;

// account
-(void) addAccounts:(NSArray *)accounts withSession:(TTSDKTicketSession *)session;
-(void) saveAccountsToUserDefaults:(NSArray *)accounts;
-(void) unlinkAccounts;

// broker utilities
-(NSString *) getBrokerDisplayString:(NSString *) value;
-(NSString *) getBrokerValueString:(NSString *) displayString;
-(NSArray *) getBrokerByValueString:(NSString *) valueString;

// navigation
-(void)returnToParentApp;



@end
