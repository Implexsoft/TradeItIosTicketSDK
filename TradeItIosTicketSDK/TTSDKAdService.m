//
//  TTSDKAdService.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 5/9/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAdService.h"

@interface TTSDKAdService()

@property NSArray * data;

@end

@implementation TTSDKAdService

- (id)init {
    if (self = [super init]) {

    }
    
    return self;
}

-(void) load {

    // used in place of real data
    self.data = @[
                              @{
                                  @"broker":@"fidelity",
                                  @"logo":@"",
                                  @"logoActive": @"1",
                                  @"offerTitle":@"Free Trades for 60 days & Up to $600",
                                  @"offerDescription": @"Open an Account",
                                  @"accountMinimum": @"$2,500",
                                  @"optionsOffer": @"$7.95 + $.75/contract",
                                  @"stocksEtfsOffer": @"$7.95 Online Trades",
                                  @"backgroundColor": [UIColor colorWithRed:80.0f/255.0f green:185.0f/255.0f blue:72.0f/255.0f alpha:1.0f],
                                  @"textColor": [UIColor whiteColor],
                                  @"buttonBackgroundColor": [UIColor colorWithRed:255.0f/255.0f green:155.0f/255.0f blue:64.0f/255.0f alpha:1.0f]
                                  },
                              @{
                                  @"broker":@"etrade",
                                  @"logo":@"",
                                  @"logoActive": @"1",
                                  @"offerTitle":@"Free Trades for 60 days & Up to $600",
                                  @"offerDescription": @"Open an Account",
                                  @"accountMinimum": @"$10,000",
                                  @"optionsOffer": @"$9.99 + $.75/contract",
                                  @"stocksEtfsOffer": @"$9.99 Online Trades",
                                  @"backgroundColor": [UIColor colorWithRed:23.0f/255.0f green:34.0f/255.0f blue:61.0f/255.0f alpha:1.0f],
                                  @"textColor": [UIColor whiteColor],
                                  @"buttonBackgroundColor": [UIColor colorWithRed:170.0f/255.0f green:123.0f/255.0f blue:228.0f/255.0f alpha:1.0f]
                                  },
                              @{
                                  @"broker":@"scottrade",
                                  @"logo":@"",
                                  @"logoActive": @"1",
                                  @"offerTitle":@"50 Free Trades",
                                  @"offerDescription": @"Open an Account",
                                  @"accountMinimum": @"$2,500",
                                  @"optionsOffer": @"$7 + $1.25/contract",
                                  @"stocksEtfsOffer": @"$7 Online Trades",
                                  @"backgroundColor": [UIColor colorWithRed:66.0f/255.0f green:20.0f/255.0f blue:106.0f/255.0f alpha:1.0f],
                                  @"textColor": [UIColor whiteColor],
                                  @"buttonBackgroundColor": [UIColor whiteColor]
                                  },
                              @{
                                  @"broker":@"optionshouse",
                                  @"logo":@"",
                                  @"logoActive": @"1",
                                  @"offerTitle":@"Free Trades for 60 days & Up to $600",
                                  @"offerDescription": @"Open an Account",
                                  @"accountMinimum": @"$2,500",
                                  @"optionsOffer": @"$4.95 + $.50/contract",
                                  @"stocksEtfsOffer": @"$4.95 Online Trades",
                                  @"backgroundColor": [UIColor colorWithRed:224.0f/255.0f green:255.0f/255.0f blue:176.0f/255.0f alpha:1.0f],
                                  @"textColor": [UIColor colorWithRed:128.0f/255.0f green:128.0f/255.0f blue:128.0f/255.0f alpha:1.0f],
                                  @"buttonBackgroundColor": [UIColor colorWithRed:154.0f/255.0f green:159.0f/255.0f blue:153.0f/255.0f alpha:1.0f]
                                  },
                              @{
                                  @"broker":@"tradeking",
                                  @"logo":@"",
                                  @"logoActive": @"1",
                                  @"offerTitle":@"$100 in free trade commission, no minimum amount!",
                                  @"offerDescription": @"Open an Account",
                                  @"accountMinimum": @"",
                                  @"optionsOffer": @"$4.95 + $.65/contract",
                                  @"stocksEtfsOffer": @"$4.95 Online Trades",
                                  @"backgroundColor": [UIColor colorWithRed:50.0f/255.0f green:50.0f/255.0f blue:100.0f/255.0f alpha:1.0f],
                                  @"textColor": [UIColor whiteColor],
                                  @"buttonBackgroundColor": [UIColor colorWithRed:58.0f/255.0f green:149.0f/255.0f blue:202.0f/255.0f alpha:1.0f]
                                  }
                              ];

    

}

@end
