//
//  BaseCalculatorViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "BaseCalculatorViewController.h"
#import "TradeItTicket.h"

@interface BaseCalculatorViewController () {
    NSArray * linkedBrokers;
    NSString * segueToBrokerSelectDetail;
}

@end

@implementation BaseCalculatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    linkedBrokers = [TradeItTicket getLinkedBrokersList];
    
    segueToBrokerSelectDetail = self.advMode ? @"advCalculatorToBrokerSelectDetail" : @"calculatorToBrokerSelectDetail";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setBroker {
    if ([self.tradeSession.authenticationInfo.id isEqualToString:@""] && [TradeItTicket hasTouchId]) {
        [self promptTouchId];
    } else if([self.tradeSession.authenticationInfo.id isEqualToString:@""]){
        if([linkedBrokers count] > 1) {
            [self showBrokerPickerAndSetPassword:NO onSelection:^{
                [self performSegueWithIdentifier:segueToBrokerSelectDetail sender:self];
            }];
        } else {
            [self setAuthentication:linkedBrokers[0] withPassword:NO];
            [self performSegueWithIdentifier:segueToBrokerSelectDetail sender:self];
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
                                if([[TradeItTicket getLinkedBrokersList] count] > 1) {
                                    [self showBrokerPickerAndSetPassword:YES onSelection:nil];
                                } else {
                                    NSString * broker = [[TradeItTicket getLinkedBrokersList] objectAtIndex:0];
                                    [self setAuthentication:broker withPassword:YES];
                                }
                            } else {
                                //too many tries, or cancelled by user
                                if(error.code == -2 || error.code == -1) {
                                    [TradeItTicket returnToParentApp:self.tradeSession];
                                } else if(error.code == -3) {
                                    //fallback mechanism selected
                                    //load username into creds
                                    //segue to login screen for the password
                                    
                                    if([[TradeItTicket getLinkedBrokersList] count] > 1) {
                                        [self showBrokerPickerAndSetPassword:NO onSelection:^{
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self performSegueWithIdentifier:segueToBrokerSelectDetail sender:self];
                                            });
                                        }];
                                    } else {
                                        NSString * broker = [[TradeItTicket getLinkedBrokersList] objectAtIndex:0];
                                        [self setAuthentication:broker withPassword:NO];
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self performSegueWithIdentifier:segueToBrokerSelectDetail sender:self];
                                        });
                                    }
                                    
                                }
                            }
                        }];
} //end promptTouchId


-(void) showBrokerPickerAndSetPassword:(BOOL) setPassword onSelection:(void (^)(void)) onSelection {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Broker"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (NSString * broker in linkedBrokers) {
            UIAlertAction * brokerOption = [UIAlertAction actionWithTitle: [TradeItTicket getBrokerDisplayString:broker] style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      
                                                                      [self setAuthentication:broker withPassword:setPassword];
                                                                      
                                                                      if(onSelection) {
                                                                          onSelection();
                                                                      }
                                                                  }];
            [alert addAction:brokerOption];
        }
        
        UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [TradeItTicket returnToParentApp:self.tradeSession];
        }];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:YES completion:nil];
    });
}

-(void) setAuthentication: (NSString *) broker withPassword: (BOOL) setPassword {
    self.tradeSession.broker = broker;
    TradeItAuthenticationInfo * creds = [TradeItTicket getStoredAuthenticationForBroker: broker];
    
    if(setPassword) {
        self.tradeSession.authenticationInfo = creds;
    } else {
        self.tradeSession.authenticationInfo.id = creds.id;
    }
}

@end
