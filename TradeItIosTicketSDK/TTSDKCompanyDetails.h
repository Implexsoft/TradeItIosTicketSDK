//
//  CompanyDetails.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/23/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTSDKCompanyDetails : UIView

@property (weak, nonatomic) IBOutlet UIButton *symbolLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *changeLabel;

-(void) populateDetailsWithSymbol: (NSString *)symbol andLastPrice:(NSNumber *)lastPrice andChange:(NSNumber *)change andChangePct:(NSNumber *)changePct;
-(void) populateSymbol: (NSString *)symbol;
-(void) populateLastPrice: (NSNumber *)lastPrice;

@end
