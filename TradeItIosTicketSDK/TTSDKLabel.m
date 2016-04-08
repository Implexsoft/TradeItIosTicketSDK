//
//  TTSDKLabel.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 4/8/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKLabel.h"
#import "TTSDKStyles.h"

@interface TTSDKLabel() {
    TTSDKStyles * styles;
}

@end

@implementation TTSDKLabel

-(id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self commonInit];
    }

    return self;
}

-(id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self commonInit];
    }

    return self;
}

-(void) commonInit {
    styles = [TTSDKStyles sharedStyles];

    self.textColor = styles.primaryTextColor;
    self.backgroundColor = [UIColor clearColor];
}

@end
