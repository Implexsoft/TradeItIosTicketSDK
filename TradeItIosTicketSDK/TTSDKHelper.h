//
//  Helper.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/4/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TTSDKCompanyDetails.h"

@interface TTSDKHelper : NSObject

@property (nonatomic, retain) UIColor * activeButtonColor;
@property (nonatomic, retain) UIColor * activeButtonHighlightColor;
@property (nonatomic, retain) UIColor * inactiveButtonColor;
@property (nonatomic, retain) UIColor * warningColor;

+ (id)sharedHelper;

-(NSString *) formatIntegerToReadablePrice: (NSString *)price;
-(NSString *) formatPriceString: (NSNumber *)num;
-(NSAttributedString *) getColoredString: (NSNumber *) number withFormat: (int) style;

-(void) addGradientToButton: (UIButton *)button;
-(void) removeGradientFromCurrentContainer;
-(void) styleFocusedInput: (UITextField *)textField withPlaceholder:(NSString *)placeholder;
-(void) styleUnfocusedInput: (UITextField *)textField withPlaceholder: (NSString *)placeholder;
-(void) styleBorderedFocusInput: (UITextField *)textField;
-(void) styleBorderedUnfocusInput: (UITextField *)textField;
-(void) styleMainActiveButton: (UIButton *)button;
-(void) styleMainInactiveButton: (UIButton *)button;
-(void) styleLoadingButton: (UIButton *)button;
-(void) initKeypadWithName: (NSString *)name intoContainer: (UIView *)container onPress: (SEL)pressed inController: (UIViewController *)vc;
-(TTSDKCompanyDetails *) companyDetailsWithName: (NSString *)name intoContainer: (UIView *)container inController: (UIViewController *)vc;

@end
