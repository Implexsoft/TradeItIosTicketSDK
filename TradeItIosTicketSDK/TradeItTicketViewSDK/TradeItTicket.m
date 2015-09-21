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
static NSString * CALC_SCREEN_PREFERENCE = @"CALC_PREFERNCE";

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
                          //@[@"Schwab",@"Schwabs"],
                          @[@"TradeStation",@"TradeStation"],
                          @[@"E*Trade",@"Etrade"],
                          @[@"Fidelity",@"Fidelity"],
                          @[@"Scottrade",@"Scottrade"],
                          @[@"Tradier Brokerage",@"Tradier"],
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

+(void) removeLinkedBroker:(NSString *)broker {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray * linkedBrokers = [[defaults objectForKey:BROKER_LIST_KEY] mutableCopy];
    NSString * brokerToRemove;
    
    if(!linkedBrokers) {
        linkedBrokers = [[NSMutableArray alloc] init];
    }
    
    int i;
    for(i = 0; i < linkedBrokers.count; i++) {
        if([linkedBrokers[i] isEqualToString: broker]) {
            brokerToRemove = linkedBrokers[i];
            break;
        }
    }
    
    if(brokerToRemove != nil) {
        [linkedBrokers removeObject: brokerToRemove];
        
        [defaults setObject:linkedBrokers forKey:BROKER_LIST_KEY];
        [defaults synchronize];
    }
}

+(void) storeUsername: (NSString *) username andPassword: (NSString *) password forBroker: (NSString *) broker {
    [Keychain saveString:username forKey:[NSString stringWithFormat:@"%@Username", broker]];
    [Keychain saveString:password forKey:[NSString stringWithFormat:@"%@Password", broker]];
}

+(TradeItAuthenticationInfo *) getStoredAuthenticationForBroker: (NSString *) broker {
    NSString * username = [Keychain getStringForKey:[NSString stringWithFormat:@"%@Username", broker]];
    NSString * password = [Keychain getStringForKey:[NSString stringWithFormat:@"%@Password", broker]];
    
    return [[TradeItAuthenticationInfo alloc] initWithId:username andPassword:password];
}

+(void) setCalcScreenPreferance: (NSString *) storyboardId {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:storyboardId forKey:CALC_SCREEN_PREFERENCE];
    [defaults synchronize];
}

//initalCalculatorController
//advCalculatorController
+(NSString *) getCalcScreenPreferance {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * pref = [defaults objectForKey:CALC_SCREEN_PREFERENCE];
    
    return pref;
}

+(BOOL) hasTouchId {
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

+(void) showTicket:(TicketSession *) tradeSession {
    //Get brokers
    [tradeSession asyncGetBrokerListWithCompletionBlock:^(NSArray *brokerList){
        if(brokerList == nil) {
            tradeSession.brokerList = [TradeItTicket getAvailableBrokers:tradeSession];
        } else {
            NSMutableArray * brokers = [[NSMutableArray alloc] init];
            
            if([tradeSession debugMode]) {
                NSArray * dummy  =  @[@"Dummy",@"Dummy"];
                [brokers addObject:dummy];
            }
            
            for (NSDictionary * broker in brokerList) {
                NSArray * entry = @[broker[@"longName"], broker[@"shortName"]];
                [brokers addObject:entry];
            }
            
            tradeSession.brokerList = (NSArray *) brokers;
        }
    }];
    
    //Get Resource Bundle
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
    NSBundle * myBundle = [NSBundle bundleWithPath:bundlePath];
    
    //Setup ticket storyboard
    NSString * startingView = @"brokerSelectController";
    
    if([[TradeItTicket getLinkedBrokersList] count] > 0) {
        tradeSession.resultContainer.status = USER_CANCELED;
        startingView = [TradeItTicket getCalcScreenPreferance];
        
        if(startingView == nil){
            if(tradeSession.calcScreenStoryboardId != nil) {
                startingView = tradeSession.calcScreenStoryboardId;
            } else {
                tradeSession.calcScreenStoryboardId = @"advCalculatorController";
                startingView = @"advCalculatorController";
            }
        } else {
            tradeSession.calcScreenStoryboardId = startingView;
        }
    } else {
        tradeSession.calcScreenStoryboardId = tradeSession.calcScreenStoryboardId != nil ? tradeSession.calcScreenStoryboardId : @"advCalculatorController";
    }
    
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: myBundle];
    UIViewController * nav = (UIViewController *)[ticket instantiateViewControllerWithIdentifier: startingView];
    [nav setModalPresentationStyle: UIModalPresentationFullScreen];
    
    if([startingView isEqualToString: @"initalCalculatorController"]) {
        CalculatorViewController * initialViewController = [((UINavigationController *)nav).viewControllers objectAtIndex:0];
        initialViewController.tradeSession = tradeSession;
    } else if([startingView isEqualToString: @"brokerSelectController"]){
        BrokerSelectViewController * initialViewController = [((UINavigationController *)nav).viewControllers objectAtIndex:0];
        initialViewController.tradeSession = tradeSession;
    } else {
        AdvCalculatorViewController * initialViewController = [((UINavigationController *)nav).viewControllers objectAtIndex:0];
        initialViewController.tradeSession = tradeSession;
    }
    
    //Display
    [tradeSession.parentView presentViewController:nav animated:YES completion:nil];
}


+(void) returnToParentApp:(TicketSession *)tradeSession {
    [[tradeSession parentView] dismissViewControllerAnimated:NO completion:^{
        if(tradeSession.callback) {
            tradeSession.callback(tradeSession.resultContainer);
        }
    }];
}

+(void) restartTicket:(TicketSession *) tradeSession {
    [[tradeSession parentView] dismissViewControllerAnimated:NO completion:nil];
    [TradeItTicket showTicket:tradeSession];
}


@end


















