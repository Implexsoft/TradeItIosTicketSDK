//
//  TTSDKTicketSession.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 2/11/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKTicketSession.h"
#import "TradeItAuthenticationResult.h"
#import "TTSDKCustomIOSAlertView.h"
#import "TTSDKLoginViewController.h"
#import "TTSDKTradeViewController.h"
#import "TTSDKPortfolioViewController.h"
#import "TradeItTradeService.h"
#import "TradeItPositionService.h"

@interface TTSDKTicketSession() {
    NSArray * questionOptions;
    UIPickerView * currentPicker;
    UIViewController * delegateViewController;
    NSString * currentSelection;
    TradeItTradeService * tradeService;
}

@end

@implementation TTSDKTicketSession

- (id) initWithConnector: (TradeItConnector *) connector andLinkedLogin:(TradeItLinkedLogin *)linkedLogin andBroker:(NSString *)broker {
    self = [super initWithConnector:connector];

    if (self) {
        self.login = linkedLogin;
        self.broker = broker;
    }

    return self;
}

- (void) createPreviewRequest {
    self.previewRequest = [[TradeItPreviewTradeRequest alloc] init];
    [self.previewRequest setOrderAction:@"buy"];
    [self.previewRequest setOrderPriceType:@"market"];
}

- (void) createPreviewRequestWithSymbol:(NSString *)symbol andAction:(NSString *)action andQuantity:(NSNumber *)quantity {
    self.previewRequest = [[TradeItPreviewTradeRequest alloc] init];

    if (action) {
        [self.previewRequest setOrderAction: action];
    } else {
        [self.previewRequest setOrderAction: @"buy"];
    }

    if (symbol) {
        [self.previewRequest setOrderSymbol: symbol];
    }

    if (quantity) {
        [self.previewRequest setOrderQuantity: quantity];
    } else {
        [self.previewRequest setOrderQuantity: @1];
    }

    [self.previewRequest setOrderPriceType: @"market"];
}

-(void) previewTrade:(void (^)(TradeItResult *)) completionBlock {
    if (!self.previewRequest) {
        return;
    }

    tradeService = [[TradeItTradeService alloc] initWithSession: self];

    [tradeService previewTrade:self.previewRequest withCompletionBlock:^(TradeItResult * res){
        completionBlock(res);
    }];
}

-(void) placeTrade:(void (^)(TradeItResult *)) completionBlock {
    if (!self.tradeRequest) {
        return;
    }

    [tradeService placeTrade: self.tradeRequest withCompletionBlock: completionBlock];
}

- (void) authenticateFromViewController:(UIViewController *)viewController withCompletionBlock:(void (^)(TradeItResult *))completionBlock {
    if (!self.login) {
        return;
    }

    delegateViewController = viewController;

    [self authenticate:self.login withCompletionBlock:^(TradeItResult * res) {
        [self authenticationRequestReceivedWithViewController:viewController withCompletionBlock:completionBlock andResult:res];
    }];
}

-(void) authenticationRequestReceivedWithViewController:(UIViewController *)viewController withCompletionBlock:(void (^)(TradeItResult *))completionBlock andResult:(TradeItResult *)res {
    if ([res isKindOfClass:TradeItAuthenticationResult.class]) {
        TradeItAuthenticationResult * result = (TradeItAuthenticationResult *)res;
        self.accounts = result.accounts;
        self.isAuthenticated = YES;
        self.broker = self.login.broker;

        if (completionBlock) {
            completionBlock(res);
        }
    } else if (viewController && [res isKindOfClass:TradeItSecurityQuestionResult.class]) {

        TradeItSecurityQuestionResult * result = (TradeItSecurityQuestionResult *)res;

        if (result.securityQuestionOptions != nil && result.securityQuestionOptions.count > 0) {
            if (![UIAlertController class]) {
                [self showOldMultiSelectWithViewController:viewController withCompletionBlock:completionBlock andSecurityQuestionResult:result];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Verify Identity"
                                                                                message: result.securityQuestion
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                
                for(NSString * title in result.securityQuestionOptions){
                    UIAlertAction * option = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        [self answerSecurityQuestion:title withCompletionBlock:^(TradeItResult * result) {
                            [self authenticationRequestReceivedWithViewController:viewController withCompletionBlock:completionBlock andResult:result];
                        }];
                    }];
                    
                    [alert addAction:option];
                }
                
                UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          [delegateViewController dismissViewControllerAnimated:YES completion:nil];
                                                                      }];
                [alert addAction:cancelAction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegateViewController presentViewController:alert animated:YES completion:nil];
                });
            }
        } else if (result.securityQuestion != nil) {
            if (![UIAlertController class]) {
                [self showOldSecQuestion:result.securityQuestion];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Security Question"
                                                                                message: result.securityQuestion
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                    [delegateViewController dismissViewControllerAnimated:YES completion:nil];
                }];
                
                UIAlertAction * submitAction = [UIAlertAction actionWithTitle:@"SUBMIT" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          [self answerSecurityQuestion: [[alert textFields][0] text] withCompletionBlock:^(TradeItResult *result) {
                                                                              [self authenticationRequestReceivedWithViewController:viewController withCompletionBlock:completionBlock andResult:result];
                                                                          }];
                                                                      }];

                [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {}];
                [alert addAction:cancelAction];
                [alert addAction:submitAction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegateViewController presentViewController:alert animated:YES completion:nil];
                });
            }
        }
    }
}

-(void) showOldSecQuestion:(NSString *) question {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:@"Security Question" message:question delegate: delegateViewController cancelButtonTitle:@"CANCEL" otherButtonTitles: @"SUBMIT", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) showOldMultiSelectWithViewController:(UIViewController *)viewController withCompletionBlock:(void (^)(TradeItResult *))completionBlock andSecurityQuestionResult:(TradeItSecurityQuestionResult *)securityQuestionResult {
    questionOptions = securityQuestionResult.securityQuestionOptions;
    currentSelection = questionOptions[0];
    
    TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView: @"Security Question"]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SUBMIT",nil]];
    
    [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
        if(buttonIndex == 0) {
            [delegateViewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self answerSecurityQuestion: currentSelection withCompletionBlock:^(TradeItResult * result) {
                [self authenticationRequestReceivedWithViewController:viewController withCompletionBlock:completionBlock andResult:result];
            }];
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

-(void) getPositionsFromAccount:(NSDictionary *)account withCompletionBlock:(void (^)(NSArray *))completionBlock {
    TradeItGetPositionsRequest * positionsRequest = [[TradeItGetPositionsRequest alloc] initWithAccountNumber:[account valueForKey:@"accountNumber"]];

    TradeItPositionService * positionService = [[TradeItPositionService alloc] initWithSession: self];

    [positionService getAccountPositions: positionsRequest  withCompletionBlock:^(TradeItResult * result) {
        if ([result isKindOfClass: TradeItGetPositionsResult.class]) {
            TradeItGetPositionsResult * positionsResult = (TradeItGetPositionsResult *)result;
            completionBlock(positionsResult.positions);
        }
    }];
}

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
    currentPicker = picker;

    [picker setDataSource: self];
    [picker setDelegate: self];
    [picker setShowsSelectionIndicator: YES];

    [contentView addSubview: picker];
    [contentView setNeedsDisplay];

    return contentView;
}

-(NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return questionOptions.count;
}



@end