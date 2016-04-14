//
//  TTSDKTextField.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 4/8/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKTextField.h"
#import "TTSDKStyles.h"

@interface TTSDKTextField() {
    TTSDKStyles * styles;
}

@end

@implementation TTSDKTextField

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

    UIView * leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, self.frame.size.height)];
    leftView.backgroundColor = [UIColor clearColor];

    self.leftView = leftView;

    self.leftViewMode = UITextFieldViewModeAlways;
}

//- (void) drawPlaceholderInRect:(CGRect)rect {
//    [self.placeholder drawInRect:rect withAttributes:@{NSForegroundColorAttributeName: styles.smallTextColor}];
//}

@end
