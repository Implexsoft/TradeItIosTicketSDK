//
//  EditViewController.h
//  TradingTicket
//
//  Created by Antonio Reyes on 6/23/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TicketSession.h"

@interface EditViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property TicketSession * tradeSession;

@end
