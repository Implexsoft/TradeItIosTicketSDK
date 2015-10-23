//
//  EditScreenViewController.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/27/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTSDKTicketSession.h"
#import "TTSDKBrokerSelectViewController.h"

@interface TTSDKEditScreenViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property TTSDKTicketSession * tradeSession;

@end
