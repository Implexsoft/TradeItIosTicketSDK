//
//  TradeItAuthController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 10/23/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKTradeItTicket.h"
#import "TradeItAuthController.h"

@implementation TradeItAuthController

+(void) getBrokers:(TTSDKTicketSession *) tradeSession {
    [tradeSession asyncGetBrokerListWithCompletionBlock:^(NSArray *brokerList){
        if(brokerList == nil) {
            tradeSession.brokerList = [TTSDKTradeItTicket getAvailableBrokers:tradeSession];
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
}

+(void) initBrokerLinkWithPublisherApp: (NSString *) publisherApp viewController:(UIViewController *) view onCompletion: (void (^)(TradeItAuthControllerResult *)) completionBlock {
    
    //Create Trade Session
    TTSDKTicketSession * tradeSession = [[TTSDKTicketSession alloc] initWithpublisherApp: publisherApp];
    tradeSession.parentView = view;
    tradeSession.brokerSignUpCallback = completionBlock;
    
    NSString * startingView = @"brokerSelectController";
    tradeSession.calcScreenStoryboardId = @"none";
    
    [TradeItAuthController getBrokers:tradeSession];
    
    //Get Resource Bundle
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
    NSBundle * myBundle = [NSBundle bundleWithPath:bundlePath];
    
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: myBundle];
    UIViewController * nav = (UIViewController *)[ticket instantiateViewControllerWithIdentifier: startingView];
    [nav setModalPresentationStyle: UIModalPresentationFullScreen];
    
    TTSDKBrokerSelectViewController * initialViewController = [((UINavigationController *)nav).viewControllers objectAtIndex:0];
    initialViewController.tradeSession = tradeSession;
    
    //Display
    [tradeSession.parentView presentViewController:nav animated:YES completion:nil];
}

+(void) linkBroker: (NSString *) broker withUsername: (NSString *) username andPassword:(NSString *) password andPublisherApp:(NSString *) publisherApp onCompletion: (void (^)(TradeItAuthControllerResult *)) completionBlock {
    TradeItAuthControllerResult * res = [[TradeItAuthControllerResult alloc] init];
    
    TradeItAuthenticationInfo * verifyCreds = [[TradeItAuthenticationInfo alloc] initWithId:username andPassword:password];
    
    TradeItVerifyCredentialSession * verifyCredsSession = [[TradeItVerifyCredentialSession alloc] initWithpublisherApp: publisherApp];
    
    [verifyCredsSession verifyUser: verifyCreds withBroker:broker WithCompletionBlock:^(TradeItResult * result){
        if([result isKindOfClass:[TradeItErrorResult class]]) {
            TradeItErrorResult * err = (TradeItErrorResult *) result;
            
            res.success = false;
            res.errorTitle = err.shortMessage;
            res.errorMessage = [err.longMessages componentsJoinedByString:@"\n"];
        } else {
            TradeItSuccessAuthenticationResult * success = (TradeItSuccessAuthenticationResult *) result;
            
            if(success.credentialsValid) {
                [TTSDKTradeItTicket storeUsername:username andPassword:password forBroker:broker];
                [TTSDKTradeItTicket addLinkedBroker:broker];
                
                res.success = true;
            } else {
                res.errorTitle = @"Invalid Credentials";
                res.errorMessage = @"Check your username and password and try again.";
                res.success = false;
            }
        }
        
        completionBlock(res);
    }];
}


+(void) unlinkBroker: (NSString *) broker {
    [TTSDKTradeItTicket removeLinkedBroker:broker];
}


+(NSArray *) getLinkedBrokers {
    return [TTSDKTradeItTicket getLinkedBrokersList];
}

+(NSString *) getBrokerDisplayString:(NSString *) brokerIdentifier {
    return [TTSDKTradeItTicket getBrokerDisplayString:brokerIdentifier];
}

@end
