//
//  CompanyDetails.h
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/23/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TradeItAccountOverviewResult.h"
#import "TTSDKPosition.h"

@interface TTSDKCompanyDetails : UIView

@property (weak, nonatomic) IBOutlet UIButton *symbolLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *changeLabel;
@property (weak, nonatomic) IBOutlet UIButton *brokerButton;
@property (weak, nonatomic) IBOutlet UIView *brokerDetails;
@property (weak, nonatomic) IBOutlet UILabel *symbolDetailValue;
@property (weak, nonatomic) IBOutlet UILabel *symbolDetailLabel;

-(void) populateDetailsWithPosition:(TTSDKPosition *)position;
-(void) populateSymbol: (NSString *)symbol;
-(void) populateLastPrice: (NSNumber *)lastPrice;
-(void) populateBrokerButtonTitle:(NSString *)broker;
-(void) populateSymbolDetail:(NSNumber *)buyingPower andSharesOwned:(NSNumber *)sharesOwned;

@end
