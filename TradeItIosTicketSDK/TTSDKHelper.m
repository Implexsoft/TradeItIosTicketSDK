//
//  Helper.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/4/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKHelper.h"

@implementation TTSDKHelper

@synthesize activeButtonColor;
@synthesize activeButtonHighlightColor;
@synthesize inactiveButtonColor;

+ (id)sharedHelper {
    static TTSDKHelper *sharedHelperInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelperInstance = [[self alloc] init];
    });

    return sharedHelperInstance;
}

- (id)init {
    if (self = [super init]) {
        activeButtonColor = [UIColor colorWithRed:38.0f/255.0f green:142.0f/255.0f blue:255.0f/255.0f alpha:1.0];
        activeButtonHighlightColor = [UIColor colorWithRed:0 green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0];
        inactiveButtonColor = [UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:200.0f/255.0f alpha:1.0f];
    }

    return self;
}

- (CAGradientLayer *)activeGradientWithBounds: (CGRect)bounds {
    CAGradientLayer *grLayer = [CAGradientLayer layer];
    grLayer.frame = bounds;
    grLayer.colors = [NSArray arrayWithObjects:
                      (id)activeButtonColor.CGColor,
                      (id)activeButtonHighlightColor.CGColor,
                      nil];
    grLayer.startPoint = CGPointMake(0, 1);
    grLayer.endPoint = CGPointMake(1, 0);


    return grLayer;
}

- (CALayer *)inactiveGradientWithBounds: (CGRect)bounds {
    CALayer *grLayer = [CALayer layer];

    grLayer.frame = bounds;
    grLayer.backgroundColor = inactiveButtonColor.CGColor;

    return grLayer;
}


@end
