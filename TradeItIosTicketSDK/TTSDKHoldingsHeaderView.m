//
//  TTSDKHoldingsHeaderView.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/21/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKHoldingsHeaderView.h"
#import "TTSDKStyles.h"

@interface TTSDKHoldingsHeaderView()

@property (weak, nonatomic) IBOutlet UIView *header;

@end

@implementation TTSDKHoldingsHeaderView

-(void) awakeFromNib {
    TTSDKStyles * styles = [TTSDKStyles sharedStyles];
    self.backgroundColor = styles.pageBackgroundColor;
    if (styles.navigationBarBackgroundColor) {
        self.header.backgroundColor = styles.navigationBarBackgroundColor;
    }
}

@end
