//
//  TradeItTicket.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/22/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TradeItTicket.h"

@implementation TradeItTicket {

}

static NSString * BROKER_LIST_KEY = @"BROKER_LIST";

+(UIColor *) activeColor {
    return [UIColor colorWithRed:0.0f
                           green:114.0f/255.0f
                            blue:188.0f/255.0f
                           alpha:1.0f];
}

+(UIColor *) baseTextColor {
    return [UIColor darkTextColor];
}

+(UIColor *) tradeItBlue {
    return [UIColor colorWithRed:81.0f/255.0f green:137.0f/255.0f blue:185.0f/255.0f alpha:1.0f];
}

+(UIColor *) tradeItLogoGray {
    return [UIColor colorWithRed:12.0f/255.0f green:52.0f/255.0f blue:85.0f/255.0f alpha:1.0f];
}

+(NSMutableAttributedString *) logoString {
    NSMutableAttributedString * text = [[NSMutableAttributedString alloc] initWithString: @"TRADEIT"];
    
    [text addAttribute:NSForegroundColorAttributeName
                 value:[TradeItTicket tradeItBlue]
                 range:NSMakeRange(0, 5)];
    
    
    [text addAttribute:NSForegroundColorAttributeName
                 value:[TradeItTicket tradeItLogoGray]
                 range:NSMakeRange(5, 2)];
    
    return text;

}

+(NSMutableAttributedString *) logoStringLite {
    NSMutableAttributedString * text = [[NSMutableAttributedString alloc] initWithString: @"TRADEIT"];
    
    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor whiteColor]
                 range:NSMakeRange(0, 5)];
    
    
    [text addAttribute:NSForegroundColorAttributeName
                 value:[TradeItTicket tradeItBlue]
                 range:NSMakeRange(5, 2)];
    
    return text;

}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToWidth: (float) i_width withInset: (float) inset {
    //UIGraphicsBeginImageContext(newSize);
    float oldWidth = image.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = image.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth + inset, newHeight), NO, 0.0);
    [image drawInRect:CGRectMake(inset, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+(NSString *) splitCamelCase:(NSString *) str {
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

+(NSArray *) getAvailableBrokers {
    NSArray * brokers = @[
                          @[@"TD Ameritrade",@"TD"],
                          @[@"Robinhood",@"Robinhood"],
                          @[@"OptionsHouse",@"OptionsHouse"],
                          @[@"Schwab",@"Schwabs"],
                          @[@"TradeStation",@"TradeStation"],
                          @[@"E*Trade",@"Etrade"],
                          @[@"Fidelity",@"Fidelity"],
                          @[@"Scottrade",@"Scottrade"],
                          @[@"Tradier",@"Tradier"],
                          @[@"Interactive Brokers",@"IB"]
                          ];
    
    return brokers;
}

+(NSArray *) getAvailableBrokers:(TicketSession *) tradeSession {
    NSArray * brokers = [TradeItTicket getAvailableBrokers];
    
    if([tradeSession debugMode]) {
        NSArray * dummy  =  @[@[@"Dummy",@"Dummy"]];
        brokers = [dummy arrayByAddingObjectsFromArray: brokers];
    }
    
    return brokers;
}

+(NSString *) getBrokerDisplayString:(NSString *) value {
    NSArray * brokers = [TradeItTicket getAvailableBrokers];
    
    for(NSArray * broker in brokers) {
        if([broker[1] isEqualToString:value]) {
            return broker[0];
        }
    }
    
    return value;
}

+(NSString *) getBrokerValueString:(NSString *) displayString {
    NSArray * brokers = [TradeItTicket getAvailableBrokers];
    
    for(NSArray * broker in brokers) {
        if([broker[0] isEqualToString:displayString]) {
            return broker[1];
        }
    }
    
    return displayString;
}

+(NSArray *) getLinkedBrokersList {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSArray * linkedBrokers = [defaults objectForKey:BROKER_LIST_KEY];
    
    return linkedBrokers;
}

+(void) addLinkedBroker:(NSString *)broker {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray * linkedBrokers = [[defaults objectForKey:BROKER_LIST_KEY] mutableCopy];
    
    if(!linkedBrokers) {
        linkedBrokers = [[NSMutableArray alloc] init];
    }
    
    int i;
    for(i = 0; i < linkedBrokers.count; i++) {
        if([linkedBrokers[i] isEqualToString: broker]) {
            break;
        }
    }
    
    if(i == linkedBrokers.count) {
        [linkedBrokers addObject: broker];
    }
    
    [defaults setObject:linkedBrokers forKey:BROKER_LIST_KEY];
    [defaults synchronize];
}

+(void) storeUsername: (NSString *) username andPassword: (NSString *) password forBroker: (NSString *) broker {
    [Keychain saveString:username forKey:[NSString stringWithFormat:@"%@Username", broker]];
    [Keychain saveString:password forKey:[NSString stringWithFormat:@"%@Passwrod", broker]];
}

+(TradeItAuthenticationInfo *) getStoredAuthenticationForBroker: (NSString *) broker {
    NSString * username = [Keychain getStringForKey:[NSString stringWithFormat:@"%@Username", broker]];
    NSString * password = [Keychain getStringForKey:[NSString stringWithFormat:@"%@Password", broker]];
    
    return [[TradeItAuthenticationInfo alloc] initWithId:username andPassword:password];
}

+(BOOL) hasTouchId {
    LAContext * myContext = [[LAContext alloc] init];
    NSError * authError = nil;
    
    if([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
        return YES;
    } else {
        return NO;
    }
}

+(void) returnToParentApp:(TicketSession *)tradeSession {
    [[tradeSession parentView] dismissViewControllerAnimated:YES completion:[tradeSession callback]];
}

@end


















