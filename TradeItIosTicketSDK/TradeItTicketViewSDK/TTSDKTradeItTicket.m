//
//  TradeItTicket.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/22/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKTradeItTicket.h"
#import "TTSDKAccountsViewController.h"
#import "TTSDKBaseViewController.h"

@implementation TTSDKTradeItTicket {

}

static NSString * BROKER_LIST_KEY = @"BROKER_LIST";
static NSString * INITIAL_SCREEN_PREFERENCE = @"INITIAL_SCREEN_PREFERENCE";

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
                          @[@"Tradier Brokerage",@"Tradier"]
                          //@[@"Interactive Brokers",@"IB"]
                          ];
    
    return brokers;
}

+(NSArray *) getAvailableBrokers:(TTSDKTicketSession *) tradeSession {
    NSArray * brokers = [TTSDKTradeItTicket getAvailableBrokers];
    
    if([tradeSession debugMode]) {
        NSArray * dummy  =  @[@[@"Dummy",@"Dummy"]];
        brokers = [dummy arrayByAddingObjectsFromArray: brokers];
    }
    
    return brokers;
}

+(NSString *) getBrokerDisplayString:(NSString *) value {
    NSArray * brokers = [TTSDKTradeItTicket getAvailableBrokers];
    
    for(NSArray * broker in brokers) {
        if([broker[1] isEqualToString:value]) {
            return broker[0];
        }
    }
    
    return value;
}

+(NSString *) getBrokerValueString:(NSString *) displayString {
    NSArray * brokers = [TTSDKTradeItTicket getAvailableBrokers];
    
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
    [TTSDKKeychain saveString:username forKey:[NSString stringWithFormat:@"%@Username", broker]];
    [TTSDKKeychain saveString:password forKey:[NSString stringWithFormat:@"%@Password", broker]];
}

+(TradeItAuthenticationInfo *) getStoredAuthenticationForBroker: (NSString *) broker {
    NSString * username = [TTSDKKeychain getStringForKey:[NSString stringWithFormat:@"%@Username", broker]];
    NSString * password = [TTSDKKeychain getStringForKey:[NSString stringWithFormat:@"%@Password", broker]];

    return [[TradeItAuthenticationInfo alloc] initWithId:username andPassword:password];
}

+(void) setInitialScreenPreference: (NSString *) storyboardId {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:storyboardId forKey:INITIAL_SCREEN_PREFERENCE];
    [defaults synchronize];
}

// initial screen (order screen or portfolio screen)
+(NSString *) getInitialScreenPreference {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * pref = [defaults objectForKey:INITIAL_SCREEN_PREFERENCE];

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

+(void) showTicket:(TTSDKTicketSession *) tradeSession {
    BOOL portfolioMode = tradeSession.portfolioMode;

    //Get brokers
    [tradeSession asyncGetBrokerListWithCompletionBlock:^(NSArray *brokerList){
        if(brokerList == nil) {
            tradeSession.brokerList = [TTSDKTradeItTicket getAvailableBrokers:tradeSession];
        } else {
            NSMutableArray * brokers = [[NSMutableArray alloc] init];
            
            if(tradeSession.debugMode) {
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
    NSString * startingView = @"linkPromptController"; //brokerSelectController

    if([[TTSDKTradeItTicket getLinkedBrokersList] count] > 0) {
        tradeSession.resultContainer.status = USER_CANCELED;
        startingView = portfolioMode ? @"portfolioController" : @"advCalculatorController";
    }

    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: myBundle];
//    UIViewController * nav = (UIViewController *)[ticket instantiateViewControllerWithIdentifier: startingView];
//    [nav setModalPresentationStyle: UIModalPresentationFullScreen];

    TTSDKBaseViewController *initialViewController = (TTSDKBaseViewController *)[ticket instantiateViewControllerWithIdentifier: @"BaseController"];
    [initialViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    [tradeSession.parentView presentViewController:initialViewController animated:YES completion:nil];
    return;

//    if([startingView isEqualToString: @"linkPromptController"]){
//        TTSDKLinkPromptViewController * initialViewController = (TTSDKLinkPromptViewController *)[ticket instantiateViewControllerWithIdentifier: startingView];
//        initialViewController.tradeSession = tradeSession;
//        [initialViewController setModalPresentationStyle:UIModalPresentationFullScreen];
//        //Display
//        [tradeSession.parentView presentViewController:initialViewController animated:YES completion:nil];
//    } else if ([startingView isEqualToString:@"portfolioController"]) {
//        TTSDKAccountsViewController * initialViewController = (TTSDKAccountsViewController *)[ticket instantiateViewControllerWithIdentifier: startingView];
//        initialViewController.tradeSession = tradeSession;
//        [initialViewController setModalPresentationStyle:UIModalPresentationFullScreen];
//        //Display
//        [tradeSession.parentView presentViewController:initialViewController animated:YES completion:nil];
//    } else {
//        TTSDKOrderViewController * initialViewController = [((UINavigationController *)nav).viewControllers objectAtIndex:0];
//        initialViewController.tradeSession = tradeSession;
//        //Display
//        [tradeSession.parentView presentViewController:nav animated:YES completion:nil];
//    }

}


+(void) returnToParentApp:(TTSDKTicketSession *)tradeSession {
    [[tradeSession parentView] dismissViewControllerAnimated:NO completion:^{
        if(tradeSession.callback) {
            tradeSession.callback(tradeSession.resultContainer);
        }
    }];
}

+(void) restartTicket:(TTSDKTicketSession *) tradeSession {
    [[tradeSession parentView] dismissViewControllerAnimated:NO completion:nil];
    [TTSDKTradeItTicket showTicket:tradeSession];
}

@end


















