//
//  Helper.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/4/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Helper : NSObject

@property (nonatomic, retain) UIColor *activeButtonColor;
@property (nonatomic, retain) UIColor *inactiveButtonColor;

+ (id)sharedHelper;

- (CAGradientLayer *)activeGradientWithBounds: (CGRect) bounds;
- (CALayer *)inactiveGradientWithBounds: (CGRect)bounds;

@end
