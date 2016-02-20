//
//  BaseCalculatorViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBaseTradeViewController.h"
#import "TradeItTradeService.h"

@interface TTSDKBaseTradeViewController() {
    TTSDKTradeItTicket * globalTicket;
}

@end

@implementation TTSDKBaseTradeViewController



static NSString * kLoginSegueIdentifier = @"TradeToLogin";



#pragma mark - Rotation

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}



#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];

    globalTicket = [TTSDKTradeItTicket globalTicket];

    // If the initial preview request still exists, go ahead and add the request to the session
    if (globalTicket.initialPreviewRequest) {
        [globalTicket passInitialPreviewRequestToSession:globalTicket.currentSession];
    }
}

-(void) checkIfAuthIsComplete {
    [self promptTouchId];
}

-(void) promptTouchId {
    LAContext * myContext = [[LAContext alloc] init];
    NSString * myLocalizedReasonString = @"Enable Broker Login to Trade";

    [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
              localizedReason:myLocalizedReasonString
                        reply:^(BOOL success, NSError *error) {
                            if (success) {
                                // TODO - set initial auth state
                            } else {
                                //too many tries, or cancelled by user
                                if(error.code == -2 || error.code == -1) {
                                    [globalTicket returnToParentApp];
                                } else if(error.code == -3) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self performSegueWithIdentifier:kLoginSegueIdentifier sender:self];
                                    });
                                }
                            }
                        }];
}



#pragma mark - Order

-(void) changeOrderAction: (NSString *) action {
    // Implement me in subclass
}

-(void) changeOrderExpiration: (NSString *) exp {
    // Implement me in subclass
}

-(void) sendPreviewRequest {
    [globalTicket.currentSession previewTrade:^(TradeItResult * res){
        if ([res isKindOfClass:TradeItPreviewTradeResult.class]) {
            globalTicket.resultContainer.status = USER_CANCELED;
            globalTicket.resultContainer.reviewResponse = (TradeItPreviewTradeResult *)res;

            [self performSegueWithIdentifier:@"TradeToReview" sender:self];
        } else if([res isKindOfClass:[TradeItErrorResult class]]){
            NSString * errorMessage = @"Could Not Complete Your Order";
            TradeItErrorResult * error = (TradeItErrorResult *)res;

            if(error.errorFields.count > 0) {
                NSString * errorField = (NSString *) error.errorFields[0];
                if([errorField isEqualToString:@"authenticationInfo"]) {
                    errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
                    
                    globalTicket.resultContainer.status = AUTHENTICATION_ERROR;
                    globalTicket.resultContainer.errorResponse = error;
                } else {
                    errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
                }
            }
            
            if(![UIAlertController class]) {
                [self showOldErrorAlert:@"Could Not Complete Order" withMessage:errorMessage];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                                message:errorMessage
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {
                                                                           [self acknowledgeAlert];
                                                                       }];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
        } else {
            if(![UIAlertController class]) {
                [self showOldErrorAlert:@"Could Not Complete Order" withMessage:@"TradeIt is temporarily unavailable. Please try again in a few minutes."];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                                message:@"TradeIt is temporarily unavailable. Please try again in a few minutes."
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {
                                                                           [self acknowledgeAlert];
                                                                       }];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
    }];
}



#pragma mark - Custom Views

-(UIView *) createPickerView: (NSString *) title {
    UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 270, 20)];
    [titleLabel setTextColor:[UIColor blackColor]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setFont: [UIFont boldSystemFontOfSize:16.0f]];
    [titleLabel setNumberOfLines:0];
    [titleLabel setText: title];
    [contentView addSubview:titleLabel];
    
    UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, 20, 270, 130)];
    self.currentPicker = picker;
    
    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [contentView addSubview:picker];
    
    [contentView setNeedsDisplay];
    return contentView;
}



#pragma mark - Picker Delegate Methods

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pickerTitles.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.pickerTitles[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.currentSelection = self.pickerValues[row];
}



#pragma mark - iOS7 fallbacks

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) showOldOrderAction {
    self.pickerTitles = @[@"Buy",@"Sell",@"Buy to Cover",@"Sell Short"];
    self.pickerValues = @[@"buy",@"sell",@"buyToCover",@"sellShort"];
    self.currentSelection = globalTicket.currentSession.previewRequest.orderAction;

    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Order Action"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 1) {
            [self changeOrderAction: self.currentSelection];
        }
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];

        if([globalTicket.currentSession.previewRequest.orderAction isEqualToString:@"sellShort"]){
            [self.currentPicker selectRow:3 inComponent:0 animated:NO];
        } else if([globalTicket.currentSession.previewRequest.orderAction isEqualToString:@"buyToCover"]){
            [self.currentPicker selectRow:2 inComponent:0 animated:NO];
        } else if([globalTicket.currentSession.previewRequest.orderAction isEqualToString:@"sell"]){
            [self.currentPicker selectRow:1 inComponent:0 animated:NO];
        }
    });
}

-(void) showOldOrderExp {
    self.pickerTitles = @[@"Good For The Day",@"Good Until Canceled"];
    self.pickerValues = @[@"day",@"gtc"];
    self.currentSelection = globalTicket.currentSession.previewRequest.orderExpiration;

    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView:@"Order Expiration"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];

    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 1) {
            [self changeOrderExpiration: self.currentSelection];
        }
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];

        if([globalTicket.currentSession.previewRequest.orderExpiration isEqualToString:@"gtc"]) {
            [self.currentPicker selectRow:1 inComponent:0 animated:NO];
        }
    });
}




-(void) acknowledgeAlert {
    // implement in sub class
}


@end
