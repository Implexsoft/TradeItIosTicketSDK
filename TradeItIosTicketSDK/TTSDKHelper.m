//
//  Helper.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/4/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//


#import "TTSDKHelper.h"

@interface TTSDKHelper () {
    UIButton * currentGradientContainer;
    CAGradientLayer * activeButtonGradient;
}

@end


@implementation TTSDKHelper

@synthesize activeButtonColor;
@synthesize activeButtonHighlightColor;
@synthesize inactiveButtonColor;
@synthesize warningColor;


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
        warningColor = [UIColor colorWithRed:236.0f/255.0f green:121.0f/255.0f blue:31.0f/255.0f alpha:1.0f];
    }

    return self;
}

- (void)addGradientToButton: (UIButton *)button {
    [self removeGradientFromCurrentContainer];

    activeButtonGradient = [CAGradientLayer layer];
    activeButtonGradient.frame = button.bounds;
    activeButtonGradient.colors = [NSArray arrayWithObjects:
                                   (id)activeButtonColor.CGColor,
                                   (id)activeButtonHighlightColor.CGColor,
                                   nil];
    activeButtonGradient.startPoint = CGPointMake(0, 1);
    activeButtonGradient.endPoint = CGPointMake(1, 0);
    activeButtonGradient.cornerRadius = button.layer.cornerRadius;

    if(button.layer.sublayers.count>0) {
        [button.layer insertSublayer:activeButtonGradient atIndex: 0];
    }else {
        [button.layer addSublayer:activeButtonGradient];
    }

    currentGradientContainer = button;
}

- (void)removeGradientFromCurrentContainer {
    if (currentGradientContainer) {
        [activeButtonGradient removeFromSuperlayer];
    }

    activeButtonGradient = nil;
    currentGradientContainer = nil;
}

- (NSString *)formatIntegerToReadablePrice: (NSString *)price {
    unsigned int len = (int)[price length];
    unichar buffer[len];
    
    [price getCharacters:buffer range:NSMakeRange(0, len)];
    
    NSMutableString * formatString = [NSMutableString string];

    int pos = 0;
    for(int i = len - 1; i >= 0; --i) {
        char current = buffer[i];
        NSString * stringToInsert;
        
        if (pos && pos % 3 == 0) {
            stringToInsert = [NSString stringWithFormat:@"%c,", current];
        } else {
            stringToInsert = [NSString stringWithFormat:@"%c", current];
        }
        
        [formatString insertString:stringToInsert atIndex:0];
        
        pos++;
    }
    
    return formatString;
}

-(void) styleMainActiveButton: (UIButton *)button {
    button.backgroundColor = activeButtonColor;
    button.layer.borderColor = [UIColor clearColor].CGColor;
    button.layer.borderWidth = 0.0f;
    button.layer.cornerRadius = button.frame.size.height / 2;

    button.layer.masksToBounds = NO;
    button.layer.shadowColor = [UIColor colorWithRed:40.0f/255.0f green:40.0f/255.0f blue:40.0f/255.0f alpha:1.0f].CGColor;
    button.layer.shadowOpacity = 0.4;
    button.layer.shadowRadius = 1;
    button.layer.shadowOffset = CGSizeMake(0,1);

    [self addGradientToButton:button];

    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(void) styleMainInactiveButton: (UIButton *)button {
    [self removeGradientFromCurrentContainer];

    button.backgroundColor = inactiveButtonColor;
    button.layer.borderColor = [UIColor clearColor].CGColor;
    button.layer.borderWidth = 0.0f;
    button.layer.cornerRadius = button.frame.size.height / 2;

    button.layer.shadowColor = [UIColor clearColor].CGColor;
    button.layer.shadowOpacity = 0;

    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(void) styleFocusedInput: (UITextField *)textField withPlaceholder: (NSString *)placeholder {
    textField.textColor = activeButtonColor;
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName: activeButtonColor}];
}

-(void) styleUnfocusedInput: (UITextField *)textField withPlaceholder: (NSString *)placeholder {
    double x = [placeholder doubleValue];

    UIColor * textColor;
    if (x > 0) {
        textColor = [UIColor blackColor];
    } else {
        textColor = inactiveButtonColor;
    }

    textField.textColor = textColor;
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName: textColor}];
}

-(void) styleBorderedFocusInput: (UITextField *)textField {
    textField.layer.borderColor = activeButtonColor.CGColor;
}

-(void) styleBorderedUnfocusInput: (UITextField *)textField {
    textField.layer.borderColor = inactiveButtonColor.CGColor;
}


@end
