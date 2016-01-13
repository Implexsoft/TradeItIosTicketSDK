//
//  BaseCalculatorViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBaseTradeViewController.h"
#import "TTSDKTradeItTicket.h"

@interface TTSDKBaseTradeViewController () {
    NSArray * linkedBrokers;
    NSString * segueToLogin;
    NSString * selectedBroker;
    UIPickerView * currentPicker;
}

@end

@implementation TTSDKBaseTradeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    linkedBrokers = [TTSDKTradeItTicket getLinkedBrokersList];

    self.tradeSession = [TTSDKTicketSession globalSession];

    segueToLogin = @"TradeToLogin";
}

-(void) setBroker {
    if (![self.tradeSession.authenticationInfo.id isEqualToString:@""] && [TTSDKTradeItTicket hasTouchId]) {
//        [self promptTouchId];
    } else if([self.tradeSession.authenticationInfo.id isEqualToString:@""]){
        if([linkedBrokers count] > 1) {
            [self showBrokerPickerAndSetPassword:NO onSelection:^{
                [self performSegueWithIdentifier:segueToLogin sender:self];
            }];
        } else if (![linkedBrokers count]) {
            return;
        } else {
            [self setAuthentication:linkedBrokers[0] withPassword:NO];
            [self performSegueWithIdentifier:segueToLogin sender:self];
        }
    }
}

-(void) promptTouchId {
    LAContext * myContext = [[LAContext alloc] init];
    NSString * myLocalizedReasonString = @"Enable Broker Login to Trade";
    
    [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
              localizedReason:myLocalizedReasonString
                        reply:^(BOOL success, NSError *error) {
                            if (success) {
                                if([[TTSDKTradeItTicket getLinkedBrokersList] count] > 1) {
                                    [self showBrokerPickerAndSetPassword:YES onSelection:nil];
                                } else {
                                    NSString * broker = [[TTSDKTradeItTicket getLinkedBrokersList] objectAtIndex:0];
                                    [self setAuthentication:broker withPassword:YES];
                                }
                            } else {
                                //too many tries, or cancelled by user
                                if(error.code == -2 || error.code == -1) {
                                    [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
                                } else if(error.code == -3) {
                                    //fallback mechanism selected
                                    //load username into creds
                                    //segue to login screen for the password
                                    
                                    if([[TTSDKTradeItTicket getLinkedBrokersList] count] > 1) {
                                        [self showBrokerPickerAndSetPassword:NO onSelection:^{
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self performSegueWithIdentifier:segueToLogin sender:self];
                                            });
                                        }];
                                    } else {
                                        NSString * broker = [[TTSDKTradeItTicket getLinkedBrokersList] objectAtIndex:0];
                                        [self setAuthentication:broker withPassword:NO];
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self performSegueWithIdentifier:segueToLogin sender:self];
                                        });
                                    }
                                    
                                }
                            }
                        }];
} //end promptTouchId


-(void) showBrokerPickerAndSetPassword:(BOOL) setPassword onSelection:(void (^)(void)) onSelection {
    if(![UIAlertController class]) {
        [self oldShowBrokerPickerAndSetPassword:setPassword onSelection:onSelection];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Broker"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (NSString * broker in linkedBrokers) {
            UIAlertAction * brokerOption = [UIAlertAction actionWithTitle: [TTSDKTradeItTicket getBrokerDisplayString:broker] style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      
                                                                      [self setAuthentication:broker withPassword:setPassword];
                                                                      
                                                                      if(onSelection) {
                                                                          onSelection();
                                                                      }
                                                                  }];
            [alert addAction:brokerOption];
        }
        
        UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
        }];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:YES completion:nil];
    });
}

-(void) setAuthentication: (NSString *) broker withPassword: (BOOL) setPassword {
    self.tradeSession.broker = broker;
    TradeItAuthenticationInfo * creds = [TTSDKTradeItTicket getStoredAuthenticationForBroker: broker];
    
    if(setPassword) {
        self.tradeSession.authenticationInfo = creds;
    } else {
        self.tradeSession.authenticationInfo.id = creds.id;
    }
}

#pragma mark - iOS7 fallbacks

-(void) oldShowBrokerPickerAndSetPassword:(BOOL) setPassword onSelection:(void (^)(void)) onSelection {
    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 0) {
            [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
        } else {
             [self setAuthentication:selectedBroker withPassword:setPassword];
             
             if(onSelection) {
                onSelection();
             }
        }
    }];
    
    selectedBroker = linkedBrokers[0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
        
        int count = 0;
        for (NSString * broker in linkedBrokers) {
            if([broker isEqualToString:self.tradeSession.broker]) {
                [currentPicker selectRow:count inComponent:0 animated:NO];
            }
            
            count++;
        }
    });
}

-(UIView *) createPickerView {
    UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 270, 20)];
    [title setTextColor:[UIColor blackColor]];
    [title setTextAlignment:NSTextAlignmentCenter];
    [title setFont: [UIFont boldSystemFontOfSize:16.0f]];
    [title setNumberOfLines:1];
    [title setText: @"Select Broker"];
    [contentView addSubview:title];
    
    UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, 20, 270, 130)];
    currentPicker = picker;
    
    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [contentView addSubview:picker];
    
    [contentView setNeedsDisplay];
    return contentView;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return linkedBrokers.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [TTSDKTradeItTicket getBrokerDisplayString:[linkedBrokers objectAtIndex:row]];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    selectedBroker = linkedBrokers[row];
}

@end















