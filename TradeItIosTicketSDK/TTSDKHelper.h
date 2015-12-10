//
//  Helper.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/4/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TTSDKHelper : NSObject

@property (nonatomic, retain) UIColor * activeButtonColor;
@property (nonatomic, retain) UIColor * activeButtonHighlightColor;
@property (nonatomic, retain) UIColor * inactiveButtonColor;
@property (nonatomic, retain) UIColor * warningColor;

+ (id)sharedHelper;

- (void)addGradientToButton: (UIButton *)button;
- (void)removeGradientFromCurrentContainer;

- (NSString *)formatIntegerToReadablePrice: (NSString *)price;
-(void) styleFocusedInput: (UITextField *)textField withPlaceholder:(NSString *)placeholder;
-(void) styleUnfocusedInput: (UITextField *)textField withPlaceholder: (NSString *)placeholder;
-(void) styleBorderedFocusInput: (UITextField *)textField;
-(void) styleBorderedUnfocusInput: (UITextField *)textField;
-(void) styleMainActiveButton: (UIButton *)button;
-(void) styleMainInactiveButton: (UIButton *)button;

@end
