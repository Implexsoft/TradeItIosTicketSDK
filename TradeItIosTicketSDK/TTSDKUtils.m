//
//  TTSDKUtils.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/4/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//


#import "TTSDKUtils.h"

@interface TTSDKUtils () {
    UIButton * currentGradientContainer;
    CAGradientLayer * activeButtonGradient;
    UIActivityIndicatorView * currentIndicator;
    UIImageView * loadingIcon;
    BOOL animating;
}

@end

@implementation TTSDKUtils

@synthesize activeButtonColor;
@synthesize activeButtonHighlightColor;
@synthesize inactiveButtonColor;
@synthesize warningColor;
@synthesize etradeColor;
@synthesize robinhoodColor;
@synthesize schwabColor;
@synthesize scottradeColor;
@synthesize fidelityColor;
@synthesize tdColor;
@synthesize optionshouseColor;


static float kDecimalSize = 5.0f;

+ (id)sharedUtils {
    static TTSDKUtils *sharedUtilsInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedUtilsInstance = [[self alloc] init];
    });

    return sharedUtilsInstance;
}

- (id)init {
    if (self = [super init]) {
        activeButtonColor = [UIColor colorWithRed:38.0f/255.0f green:142.0f/255.0f blue:255.0f/255.0f alpha:1.0];
        activeButtonHighlightColor = [UIColor colorWithRed:0 green:122.0f/255.0f blue:255.0f/255.0f alpha:1.0];
        inactiveButtonColor = [UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:200.0f/255.0f alpha:1.0f];
        warningColor = [UIColor colorWithRed:236.0f/255.0f green:121.0f/255.0f blue:31.0f/255.0f alpha:1.0f];
        etradeColor = [UIColor colorWithRed:98.0f / 255.0f green:77.0f / 255.0f blue:160.0f / 255.0f alpha:1.0f];
        robinhoodColor = [UIColor colorWithRed:33.0f / 255.0f green:206.0f / 255.0f blue:153.0f / 255.0f alpha:1.0f];
        schwabColor = [UIColor colorWithRed:25.0f / 255.0f green:159.0f / 255.0f blue:218.0f / 255.0f alpha:1.0f];
        scottradeColor = [UIColor colorWithRed:69.0f / 255.0f green:40.0f / 255.0f blue:112.0f / 255.0f alpha:1.0f];
        fidelityColor = [UIColor colorWithRed:74.0f / 255.0f green:145.0f / 255.0f blue:46.0f / 255.0f alpha:1.0f];
        tdColor = [UIColor colorWithRed:2.0f / 255.0f green:182.0f / 255.0f blue:36.0f / 255.0f alpha:1.0f];
        optionshouseColor = [UIColor colorWithRed:46.0f / 255.0f green:98.0f / 255.0f blue:9.0f / 255.0f alpha:1.0f];
    }

    return self;
}

-(CGFloat) retrieveScreenHeight {
    return [[UIScreen mainScreen] bounds].size.height;
}

-(BOOL) isSmallScreen {
    return ([self retrieveScreenHeight] < 500);
}

-(UIColor *) retrieveBrokerColorByBrokerName:(NSString *)brokerName {
    UIColor * brokerColor;

    @try {
        brokerColor = [self valueForKey: [NSString stringWithFormat:@"%@Color", [brokerName lowercaseString]]];
    }
    @catch (NSException *exception) {
        brokerColor = activeButtonColor;
    }

    return brokerColor;
}

- (void)addGradientToButton: (UIButton *)button {
    [self removeGradientFromCurrentContainer];
    [self removeLoadingIndicatorFromContainer];

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

- (CAShapeLayer *)retrieveCircleGraphicWithSize:(CGFloat)diameter andColor:(UIColor *)color {
    CAShapeLayer * circleLayer = [CAShapeLayer layer];
    [circleLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 1.5, diameter, diameter)] CGPath]];
    [circleLayer setFillColor: color.CGColor];

    return circleLayer;
}

- (void)removeLoadingIndicatorFromContainer {
    if (currentIndicator) {
        [currentIndicator removeFromSuperview];
    }
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

-(void) styleCustomDropdownButton: (UIButton *)button {
    button.backgroundColor = [UIColor whiteColor];
    button.layer.borderColor = activeButtonColor.CGColor;
    button.layer.borderWidth = 1.5f;
    button.layer.cornerRadius = button.frame.size.height / 2;

    UILabel * preferredBrokerLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 0, button.frame.size.width, 8)];
    preferredBrokerLabel.font = [UIFont systemFontOfSize:8.0f];
    preferredBrokerLabel.textColor = [UIColor lightGrayColor];
    preferredBrokerLabel.text = @"PREFERRED BROKER";

    [button.titleLabel addSubview:preferredBrokerLabel];
    [button setTitleColor:[UIColor colorWithRed:20.0f/255.0f green:20.0f/255.0f blue:20.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
}

-(void) styleLoadingButton: (UIButton *)button {
    [self removeGradientFromCurrentContainer];
    [self removeLoadingIndicatorFromContainer];

    currentIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    currentIndicator.hidden = NO;
    [button addSubview:currentIndicator];
    currentIndicator.frame = CGRectMake(button.titleLabel.frame.origin.x + button.titleLabel.frame.size.width + 10.0, button.titleLabel.frame.origin.y, 20.0, 20.0);
    [currentIndicator bringSubviewToFront:button];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
    [currentIndicator startAnimating];

//    loadingIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"success_icon.png"]];
//    loadingIcon.frame = CGRectMake(button.titleLabel.frame.origin.x + button.titleLabel.frame.size.width + 10.0, button.titleLabel.frame.origin.y, 20.0, 20.0);
//    [button addSubview:loadingIcon];
//    [self startSpin];
}

- (void) spinWithOptions: (UIViewAnimationOptions) options {
    // this spin completes 360 degrees every 2 seconds
    [UIView animateWithDuration: 0.5f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         loadingIcon.transform = CGAffineTransformRotate(loadingIcon.transform, M_PI / 2);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if (animating) {
                                 // if flag still set, keep spinning with constant speed
                                 [self spinWithOptions: UIViewAnimationOptionCurveLinear];
                             } else if (options != UIViewAnimationOptionCurveEaseOut) {
                                 // one last spin, with deceleration
                                 [self spinWithOptions: UIViewAnimationOptionCurveEaseOut];
                             }
                         }
                     }];
}

- (void) startSpin {
    if (!animating) {
        animating = YES;
        [self spinWithOptions: UIViewAnimationOptionCurveEaseIn];
    }
}

- (void)initKeypadWithName: (NSString *)name intoContainer: (UIView *)container onPress: (SEL)pressed inController: (UIViewController *)vc {
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
    NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];
    NSArray * keypadArray = [resourceBundle loadNibNamed:name owner:self options:nil];
    
    UIView * keypad = [keypadArray firstObject];
    
    CGRect frame = CGRectMake(0, 0, container.frame.size.width, container.frame.size.height);
    keypad.frame = frame;
    
    [container addSubview:keypad];
    keypad.userInteractionEnabled = YES;
    NSArray * subviews = keypad.subviews;

    [keypad updateConstraints];
    [keypad layoutSubviews];
    [keypad layoutIfNeeded];

    for (int i = 0; i < [subviews count]; i++) {
        if (![NSStringFromClass([[subviews objectAtIndex:i] class]) isEqualToString:@"UIImageView"]) {
            UIButton *button = [subviews objectAtIndex:i];

            if (button.tag == 10) { // decimal
                if ([vc.restorationIdentifier isEqualToString:@"tradeViewController"]) {
                    button.hidden = YES;
                    button.userInteractionEnabled = NO;
                } else {
                    UIView * circleView = [[UIView alloc] initWithFrame:CGRectMake((button.bounds.size.width / 2) - kDecimalSize, (button.bounds.size.height / 2) - kDecimalSize, kDecimalSize, kDecimalSize)];
                    CAShapeLayer * circle = [self retrieveCircleGraphicWithSize:5.0f andColor:activeButtonColor];
                    circle.frame = CGRectMake(-2.0f, -2.0f, kDecimalSize, kDecimalSize);
                    [circleView.layer addSublayer:circle];
                    [button addSubview:circleView];

                    NSLayoutConstraint *xCenterConstraint = [NSLayoutConstraint constraintWithItem:circleView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
                    [button addConstraint:xCenterConstraint];
                    
                    NSLayoutConstraint *yCenterConstraint = [NSLayoutConstraint constraintWithItem:circleView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
                    [button addConstraint:yCenterConstraint];
                }
            }

            [button addTarget:vc action:pressed forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

-(TTSDKCompanyDetails *) companyDetailsWithName: (NSString *)name intoContainer: (UIView *)container inController: (UIViewController *)vc {
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
    NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];
    NSArray * companyDetailsArray = [resourceBundle loadNibNamed:@"TTSDKCompanyDetailsView" owner:vc options:nil];

    TTSDKCompanyDetails * companyDetailsNib = [companyDetailsArray firstObject];
    CGRect frame = CGRectMake(0, 0, container.frame.size.width, container.frame.size.height);
    companyDetailsNib.frame = frame;

    if ([vc.restorationIdentifier isEqualToString:@"tradeViewController"]) {
        companyDetailsNib.brokerDetails.hidden = NO;
    } else {
        companyDetailsNib.brokerDetails.hidden = YES;
    }

    [container addSubview:companyDetailsNib];

    return [companyDetailsNib init];
}

-(TTSDKCustomAlertView *) customAlertWithVC:(UIViewController *)vc {
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
    NSBundle * resourceBundle = [NSBundle bundleWithPath:bundlePath];
    NSArray * customAlertArray = [resourceBundle loadNibNamed:@"TTSDKCustomAlertView" owner:vc options:nil];

    TTSDKCustomAlertView * customAlert = [customAlertArray firstObject];
    CGRect frame = CGRectMake(0, 0, vc.view.frame.size.width, vc.view.frame.size.height);
    customAlert.frame = frame;

    return customAlert;
}

- (void) stopSpin {
    // set the flag to stop spinning after one last 90 degree increment
    animating = NO;
}

-(void) styleMainInactiveButton: (UIButton *)button {
    [self removeGradientFromCurrentContainer];
    [self removeLoadingIndicatorFromContainer];

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

-(NSString *) formatPriceString: (NSNumber *)num {
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: US];

    return [formatter stringFromNumber: num];
}

-(double) numberFromPriceString: (NSString *)priceString {
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: US];

    return [formatter numberFromString:priceString].doubleValue;
}

-(NSString *) splitCamelCase:(NSString *) str {
    NSMutableString * str2 = [NSMutableString string];

    for (NSInteger i=0; i < str.length; i++){
        NSString *ch = [str substringWithRange:NSMakeRange(i, 1)];
        if ([ch rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location != NSNotFound) {
            [str2 appendString:@" "];
        }
        [str2 appendString:ch];
    }
    
    return str2.capitalizedString;
}

-(NSMutableAttributedString *) logoStringLight {
    NSMutableAttributedString * text = [[NSMutableAttributedString alloc] initWithString: @"TRADEIT"];
    
    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor lightGrayColor]
                 range:NSMakeRange(0, 5)];
    
    [text addAttribute:NSForegroundColorAttributeName
                 value:activeButtonColor
                 range:NSMakeRange(5, 2)];

    return text;
}

-(NSAttributedString *) getColoredString: (NSNumber *) number withFormat: (int) style {
    UIColor * positiveColor = [UIColor colorWithRed:58.0f/255.0f green:153.0f/255.0f blue:69.0f/255.0f alpha:1.0f];
    UIColor * negativeColor = [UIColor colorWithRed:197.0f/255.0f green:81.0f/255.0f blue:75.0f/255.0f alpha:1.0f];
    
    NSMutableAttributedString * attString;
    if([number doubleValue] > 0) {
        attString = [[NSMutableAttributedString alloc] initWithString:@"\u25B2"];
    } else {
        attString = [[NSMutableAttributedString alloc] initWithString:@"\u25BC"];
    }

    double absValue = fabs([number doubleValue]);
    NSString * asString = [self formatPriceString:[NSNumber numberWithDouble:absValue]];
    [attString appendAttributedString:[[NSAttributedString alloc] initWithString:asString]];

    if(style == NSNumberFormatterDecimalStyle) {
        [attString appendAttributedString:[[NSAttributedString alloc] initWithString:@"%"]];
    }

    if([number doubleValue] > 0) {
        [attString addAttribute:NSForegroundColorAttributeName
                          value:positiveColor
                          range:NSMakeRange(0, [attString length])];
    } else {
        [attString addAttribute:NSForegroundColorAttributeName
                          value:negativeColor
                          range:NSMakeRange(0, [attString length])];
    }

    return (NSAttributedString *) attString;
}

-(BOOL) containsString: (NSString *) base searchString: (NSString *) searchString {
    NSRange range = [base rangeOfString:searchString];
    return range.length != 0;
}

-(BOOL) hasTouchId {
    if(![LAContext class]) {
        return NO;
    }
    
    LAContext * myContext = [[LAContext alloc] init];
    NSError * authError = nil;
    
    if([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
        return YES;
    } else {
        return NO;
    }
}

@end
