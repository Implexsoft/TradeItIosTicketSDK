//
//  TTSDKBrokerSelectFooterView.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 5/2/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TradeItIosAdSdk/TradeItIosAdSdk-Swift.h>

@interface TTSDKBrokerSelectFooterView : UIView

@property (weak, nonatomic) IBOutlet UIButton *help;
@property (weak, nonatomic) IBOutlet UIButton *privacy;
@property (weak, nonatomic) IBOutlet UIButton *terms;
@property (weak, nonatomic) IBOutlet TradeItAdView *adView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *adViewHeightConstraint;

@end
