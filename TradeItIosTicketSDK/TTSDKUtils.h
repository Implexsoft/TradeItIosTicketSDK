//
//  TTSDKUtils.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/4/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TTSDKCompanyDetails.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface TTSDKUtils : NSObject

@property (nonatomic, retain) UIColor * activeButtonColor;
@property (nonatomic, retain) UIColor * activeButtonHighlightColor;
@property (nonatomic, retain) UIColor * inactiveButtonColor;
@property (nonatomic, retain) UIColor * warningColor;
@property (nonatomic, retain) UIColor * etradeColor;
@property (nonatomic, retain) UIColor * robinhoodColor;
@property (nonatomic, retain) UIColor * schwabColor;
@property (nonatomic, retain) UIColor * scottradeColor;
@property (nonatomic, retain) UIColor * fidelityColor;
@property (nonatomic, retain) UIColor * tdColor;
@property (nonatomic, retain) UIColor * optionshouseColor;

+ (id)sharedUtils;

-(NSString *) formatIntegerToReadablePrice: (NSString *)price;
-(NSString *) formatPriceString: (NSNumber *)num;
-(double) numberFromPriceString: (NSString *)priceString;
-(NSAttributedString *) getColoredString: (NSNumber *) number withFormat: (int) style;
-(NSMutableAttributedString *) logoStringLight;
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
-(NSString *) splitCamelCase:(NSString *) str;
-(BOOL) containsString: (NSString *) base searchString: (NSString *) searchString;
-(TTSDKCompanyDetails *) companyDetailsWithName: (NSString *)name intoContainer: (UIView *)container inController: (UIViewController *)vc;
- (CAShapeLayer *)retrieveCircleGraphicWithSize:(CGFloat)diameter andColor:(UIColor *)color;
-(void) styleCustomDropdownButton: (UIButton *)button;
-(UIColor *) retrieveBrokerColorByBrokerName:(NSString *)brokerName;
-(CGFloat) retrieveScreenHeight;
-(BOOL) isSmallScreen;
-(BOOL) hasTouchId;
-(NSString *) getBrokerUsername:(NSString *) broker;

@end