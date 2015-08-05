//
//  ThemeManager.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/5/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Theme.h"
#import "DefaultDarkTheme.h"

@interface ThemeManager : NSObject

+(id <Theme>) theme;

@end
