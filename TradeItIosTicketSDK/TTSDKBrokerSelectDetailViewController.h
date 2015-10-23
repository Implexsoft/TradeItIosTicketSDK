//
//  BrokerSelectDetailViewController.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/21/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKLoadingScreenViewController.h"
#import "TTSDKTicketSession.h"

@interface TTSDKBrokerSelectDetailViewController : UIViewController <UITextFieldDelegate>

@property TTSDKTicketSession * tradeSession;
@property BOOL cancelToParent;

@property NSString * addBroker;

@end
