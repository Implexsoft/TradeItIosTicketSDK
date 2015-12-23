//
//  OrderTypeInputViewController.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/18/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKTicketSession.h"

@interface TTSDKOrderTypeInputViewController : UIViewController <UITextFieldDelegate>

@property NSString * orderType;
@property TTSDKTicketSession * tradeSession;

@end
