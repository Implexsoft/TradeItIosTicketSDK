//
//  TradeItIosTicketSDK.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/9/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TradeItTicketController.h"
#import "TradeItTicketControllerResult.h"
#import "TradeItAuthControllerResult.h"
#import "TradeItAuthenticationInfo.h"
#import "TradeItErrorResult.h"
#import "TradeItRequest.h"
#import "TradeItSecurityQuestionRequest.h"
#import "TradeItSecurityQuestionResult.h"
#import "TIEMSJSONModel.h"
#import "TIEMSJSONAPI.h"
#import "TIEMSJSONHTTPClient.h"
#import "TIEMSJSONKeyMapper.h"
#import "TIEMSJSONModel+networking.h"
#import "TIEMSJSONModelArray.h"
#import "TIEMSJSONModelClassProperty.h"
#import "TIEMSJSONModelError.h"
#import "TIEMSJSONModelLib.h"
#import "TIEMSJSONValueTransformer.h"
#import "NSArray+TIEMSJSONModel.h"


// Imports to use the underlying TradeItIosEmsLib


// Generic classes for the request/results sent the to EMS server
#import "TradeItRequest.h"
#import "TradeItResult.h"
#import "TradeItErrorResult.h"

// Start with the connector, you'll set your API key and the environment
// Then link a user to their brokerage(s) account(s)
#import "TradeItConnector.h"
#import "TradeItLinkedLogin.h"
#import "TradeItAuthenticationInfo.h"
#import "TradeItAuthenticationRequest.h"
#import "TradeItAuthenticationResult.h"
#import "TradeItAuthLinkRequest.h"
#import "TradeItAuthLinkResult.h"

// Once you have a link you'll establish a session using the linkedLogin
#import "TradeItSession.h"
#import "TradeItSecurityQuestionRequest.h"
#import "TradeItSecurityQuestionResult.h"

// Use the PublisherService to retrieve ad sources
#import "TradeItAdsRequest.h"
#import "TradeitAdsResult.h"

// Use the TradeService to preview and place trades
#import "TradeItTradeService.h"
#import "TradeItPreviewTradeRequest.h"
#import "TradeItPreviewTradeOrderDetails.h"
#import "TradeItPreviewTradeResult.h"
#import "TradeItPlaceTradeRequest.h"
#import "TradeItPlaceTradeResult.h"
#import "TradeItPlaceTradeOrderInfo.h"
#import "TradeItPlaceTradeOrderInfoPrice.h"

// Use the BalanceService to get account balance information
#import "TradeItBalanceService.h"
#import "TradeItAccountOverviewRequest.h"
#import "TradeItAccountOverviewResult.h"

// Use the PositionSerview to get account position information
#import "TradeItPositionService.h"
#import "TradeItGetPositionsRequest.h"
#import "TradeItGetPositionsResult.h"
#import "TradeItPosition.h"

// Use the PublisherService to get publisher specific configurations/data
#import "TradeItPublisherService.h"
#import "TradeItAdsRequest.h"
#import "TradeItAdsResult.h"

// EMS API Util classes
#import "TradeItTypeDefs.h"

@interface TradeItIosTicketSDK : NSObject

@end
