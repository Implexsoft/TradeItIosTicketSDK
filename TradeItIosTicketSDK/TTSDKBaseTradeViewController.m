//
//  BaseCalculatorViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 8/2/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKBaseTradeViewController.h"
#import "TradeItTradeService.h"
#import "TradeItMarketDataService.h"
#import "TradeItQuotesResult.h"


@implementation TTSDKBaseTradeViewController

static NSString * kLoginSegueIdentifier = @"TradeToLogin";


#pragma mark - Initialization

-(void) viewDidLoad {
    [super viewDidLoad];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
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
                                    [self.ticket returnToParentApp];
                                } else if(error.code == -3) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self performSegueWithIdentifier:kLoginSegueIdentifier sender:self];
                                    });
                                }
                            }
                        }];
}


#pragma mark - Order

-(void) retrieveQuoteData {
    TradeItQuote * quote = self.ticket.quote;
    if (!quote.symbol) {
        return;
    }

    TradeItMarketDataService * quoteService = [[TradeItMarketDataService alloc] initWithSession:self.ticket.currentSession];

    TradeItQuotesRequest * quotesRequest = [[TradeItQuotesRequest alloc] initWithSymbol:quote.symbol];
    [quoteService getQuoteData:quotesRequest withCompletionBlock:^(TradeItResult * res){
        if ([res isKindOfClass:TradeItQuotesResult.class]) {
            TradeItQuotesResult * result = (TradeItQuotesResult *)res;
            TradeItQuote * resultQuote = [[TradeItQuote alloc] initWithQuoteData:(NSDictionary *)[result.quotes objectAtIndex:0]];
            self.ticket.quote = resultQuote;
        }

        [self populateSymbolDetails];
    }];
}

-(void) retrieveAccountSummaryData {
    self.currentPortfolioAccount = [[TTSDKPortfolioAccount alloc] initWithAccountData: self.ticket.currentAccount];

    [self.currentPortfolioAccount retrieveAccountSummaryWithCompletionBlock:^(void){
        [self populateSymbolDetails];
    }];
}

-(void) populateSymbolDetails {
    // Implement me in subclass
}

-(void) changeOrderAction: (NSString *) action {
    // Implement me in subclass
}

-(void) changeOrderExpiration: (NSString *) exp {
    // Implement me in subclass
}

-(void) acknowledgeAlert {
    // implement in sub class
}

-(void) sendPreviewRequest {
    [self.ticket.currentSession previewTrade:self.ticket.previewRequest withCompletionBlock:^(TradeItResult * res){
        if ([res isKindOfClass:TradeItPreviewTradeResult.class]) {
            self.ticket.resultContainer.status = USER_CANCELED;
            self.ticket.resultContainer.reviewResponse = (TradeItPreviewTradeResult *)res;

            [self performSegueWithIdentifier:@"TradeToReview" sender:self];
        } else if([res isKindOfClass:[TradeItErrorResult class]]){
            NSString * errorMessage = @"Could Not Complete Your Order";
            TradeItErrorResult * error = (TradeItErrorResult *)res;

            if(error.errorFields.count > 0) {
                NSString * errorField = (NSString *) error.errorFields[0];
                if([errorField isEqualToString:@"authenticationInfo"]) {
                    errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
                    
                    self.ticket.resultContainer.status = AUTHENTICATION_ERROR;
                    self.ticket.resultContainer.errorResponse = error;
                } else {
                    errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
                }
            } else if (error.longMessages.count > 0) {
                errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
            }

            if(![UIAlertController class]) {
                [self showOldErrorAlert:@"Could Not Complete Order" withMessage:errorMessage];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                                message:errorMessage
                                                                         preferredStyle:UIAlertControllerStyleAlert];

                alert.modalPresentationStyle = UIModalPresentationPopover;

                UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {
                                                                           [self acknowledgeAlert];
                                                                       }];
                [alert addAction:defaultAction];

                [self presentViewController:alert animated:YES completion:nil];

                UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
                alertPresentationController.sourceView = self.view;
                alertPresentationController.permittedArrowDirections = 0;
                alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
            }
        } else {
            if(![UIAlertController class]) {
                [self showOldErrorAlert:@"Could Not Complete Order" withMessage:@"TradeIt is temporarily unavailable. Please try again in a few minutes."];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                                message:@"TradeIt is temporarily unavailable. Please try again in a few minutes."
                                                                         preferredStyle:UIAlertControllerStyleAlert];

                alert.modalPresentationStyle = UIModalPresentationPopover;

                UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction * action) {
                                                                           [self acknowledgeAlert];
                                                                       }];
                [alert addAction:defaultAction];

                [self presentViewController:alert animated:YES completion:nil];

                UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
                alertPresentationController.sourceView = self.view;
                alertPresentationController.permittedArrowDirections = 0;
                alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
            }
        }
    }];
}


@end
