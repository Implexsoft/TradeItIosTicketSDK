//
//  EditScreenViewController.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/27/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TicketSession.h"
#import "BrokerSelectViewController.h"

@interface EditScreenViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property TicketSession * tradeSession;

@end
