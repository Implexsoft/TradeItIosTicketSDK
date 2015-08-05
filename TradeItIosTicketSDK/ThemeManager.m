//
//  ThemeManager.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/5/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "ThemeManager.h"

@implementation ThemeManager

+(id <Theme>) theme {
    //determine which theme to use
    
    return [DefaultDarkTheme new];
}

@end
