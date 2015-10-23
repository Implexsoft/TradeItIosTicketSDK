//
//  AdvCalcTextField.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/30/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKAdvCalcTextField.h"

@implementation TTSDKAdvCalcTextField

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset( bounds , 5 , 5 );
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset( bounds , 5 , 5 );
}

@end
