//
//  TicketController.m
//  TradeItTicketViewSDK
//
//  Created by Antonio Reyes on 7/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TradeItTicketController.h"
#import "TicketSession.h"

#import "CalculatorViewController.h"
#import "InitialNavigationViewController.h"
#import "EditViewController.h"
#import "LoginViewController.h"
#import "LoadingScreenViewController.h"
#import "ReviewScreenViewController.h"
#import "SuccessViewController.h"


@implementation TradeItTicketController

+(void) showFullTicketWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol lastPrice:(double) lastPrice viewController:(UIViewController *) view {
    [TradeItTicketController showFullTicketWithPublisherApp:publisherApp symbol:symbol lastPrice:lastPrice viewController:view onCompletion:nil];
}

+(void) showFullTicketWithPublisherApp: (NSString *) publisherApp symbol:(NSString *) symbol lastPrice:(double) lastPrice viewController:(UIViewController *) view onCompletion:(void(^)(void)) callback {

    [TradeItTicketController forceClassesIntoLinker];
    
    //Get Resource Bundle
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
    NSBundle * myBundle = [NSBundle bundleWithPath:bundlePath];
    
    //Setup ticket storyboard
    UIStoryboard * ticket = [UIStoryboard storyboardWithName:@"Ticket" bundle: myBundle];
    UIViewController * nav = (UIViewController *)[ticket instantiateInitialViewController];
    [nav setModalPresentationStyle: UIModalPresentationFullScreen];
    
    //Create Trade Session
    CalculatorViewController * calcViewController= (CalculatorViewController *)[((UINavigationController *)nav).viewControllers objectAtIndex:0];
    calcViewController.tradeSession = [[TicketSession alloc]initWithpublisherApp: publisherApp];
    calcViewController.tradeSession.orderInfo.symbol = [symbol uppercaseString];
    calcViewController.tradeSession.lastPrice = lastPrice;
    calcViewController.tradeSession.callback = callback;
    calcViewController.tradeSession.parentView = view;
    
    //Display
    [view presentViewController:nav animated:YES completion:nil];
}


//Let me tell you a cool story about why this is here:
//Storyboards in bundles are static, non-compilled resources
//Therefore when the linker goes through the library it doesn't
//think any of the classes setup for the storyboard are in use
//so when we actually go to load up the storyboard, it explodes
//because all those classes aren't loaded into the app. So,
//we simply call a lame method on every view class which forces
//the linker to load the classes :)
+(void) forceClassesIntoLinker {
    [CalculatorViewController class];
    [InitialNavigationViewController class];
    [EditViewController class];
    [LoginViewController class];
    [LoadingScreenViewController class];
    [ReviewScreenViewController class];
    [SuccessViewController class];
}

@end
