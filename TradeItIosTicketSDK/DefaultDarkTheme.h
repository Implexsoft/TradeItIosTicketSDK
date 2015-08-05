//
//  DefaultDarkTheme.h
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/5/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Theme.h"

@interface DefaultDarkTheme : NSObject <Theme>

-(void) themeOrderEntryPageBody:(UIView *) body;
-(void) themeEditPageBody: (UIView *) body;
-(void) themeLoadingPageBody: (UIView *) body;
-(void) themeReviewPageBody: (UIView *) body;
-(void) themeSuccessPageBody: (UIView *) body;

@end

@implementation DefaultDarkTheme

-(void) themeEntryPagesBody: (UIView *) body {
    body.backgroundColor = [UIColor grayColor];
}

-(void) themePassivePagesBody:(UIView *)body {
    body.backgroundColor = [UIColor blackColor];
}

@end
