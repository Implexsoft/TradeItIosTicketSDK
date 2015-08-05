//
//  ThemeProtocol.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/5/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol Theme <NSObject>

-(void) themeEntryPagesBody:(UIView *) body;
-(void) themePassivePagesBody:(UIView *) body;


@end
