//
//  TTSDKCustomAlertView.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/8/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTSDKCustomAlertView : UIView

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentHeightConstraint;

@end
