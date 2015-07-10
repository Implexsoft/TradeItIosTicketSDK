//
//  TicketController.h
//  TradeItTicketViewSDK
//
//  Created by Antonio Reyes on 7/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TradeItStockOrEtfTradeSession.h"

@interface TradeItTicketController : NSObject

+(void) showFullTicketWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol viewController:(UIViewController *) view;

+(void) showFullTicketWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol viewController:(UIViewController *) view onCompletion:(void(^)(void)) callback;


@end
