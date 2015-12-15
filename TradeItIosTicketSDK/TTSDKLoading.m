//
//  TTSDKLoading.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 12/11/15.
//  Copyright © 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKLoading.h"
#import "TTSDKAdvCalculatorViewController.h"

@implementation TTSDKLoading

#pragma mark - Actions To Perform While Loading



- (void) verifyCredentials {
    TradeItVerifyCredentialSession * verifyCredsSession = [[TradeItVerifyCredentialSession alloc] initWithpublisherApp: self.tradeSession.publisherApp];
    NSString * broker = self.addBroker != nil ? self.addBroker : self.tradeSession.broker;

    [verifyCredsSession verifyUser: self.verifyCreds withBroker:broker WithCompletionBlock:^(TradeItResult * res){
//         [self verifyCredentialsRequestRecieved: res];
    }];
}

-(void) verifyCredentialsWithCompletionBlock: (void (^)(void))localBlock {
    TradeItVerifyCredentialSession * verifyCredsSession = [[TradeItVerifyCredentialSession alloc] initWithpublisherApp: self.tradeSession.publisherApp];
//    NSString * broker = self.addBroker != nil ? self.addBroker : self.tradeSession.broker;

    TradeItResult * result = [[TradeItResult alloc] init];

    [self verifyCredentialsRequestRecieved:result onComplete:localBlock];

//    [verifyCredsSession verifyUser: self.verifyCreds withBroker:broker WithCompletionBlock:^(TradeItResult * res){
//        [self verifyCredentialsRequestRecieved: res onComplete:localBlock];
//    }];
}

-(void) verifyCredentialsRequestRecieved: (TradeItResult *) result onComplete:(void (^)(void))localBlock {

    localBlock();
    return;

//    if([result isKindOfClass:[TradeItErrorResult class]]) {
//        TradeItErrorResult * err = (TradeItErrorResult *) result;
//
//        self.tradeSession.errorTitle = err.shortMessage;
//        self.tradeSession.errorMessage = [err.longMessages componentsJoinedByString:@"\n"];
//    } else {
//        TradeItSuccessAuthenticationResult * success = (TradeItSuccessAuthenticationResult *) result;
//        NSString * broker = self.addBroker != nil ? self.addBroker : self.tradeSession.broker;
//
//        if(success.credentialsValid) {
//            [TTSDKTradeItTicket storeUsername:self.verifyCreds.id andPassword:self.verifyCreds.password forBroker:broker];
//            [TTSDKTradeItTicket addLinkedBroker:broker];
//            self.tradeSession.resultContainer.status = USER_CANCELED;
//
//            if(self.addBroker) {
//                self.tradeSession.broker = self.addBroker;
//            }
//
//            self.tradeSession.authenticationInfo = self.verifyCreds;
//
//            if([self.tradeSession.calcScreenStoryboardId isEqualToString:@"none"]) {
//                self.tradeSession.brokerSignUpComplete = true;
//                // [self dismissViewControllerAnimated:YES completion:nil];
//            }
//            else if([self.tradeSession.calcScreenStoryboardId isEqualToString:@"initalCalculatorController"]) {
//                // [self performSegueWithIdentifier:@"loginToCalculator" sender:self];
//            } else {
//                // [self performSegueWithIdentifier:@"loginToAdvCalculator" sender:self];
//            }
//        } else {
//            self.tradeSession.errorTitle = @"Invalid Credentials";
//            self.tradeSession.errorMessage = @"Check your username and password and try again.";
//
//            if(!self.addBroker) {
//                [TTSDKTradeItTicket storeUsername:self.verifyCreds.id andPassword:@"" forBroker:broker];
//                [TTSDKTradeItTicket removeLinkedBroker: broker];
//            }
//
//            // [self dismissViewControllerAnimated:YES completion:nil];
//        }
//    }
//
//    localBlock();
}

- (void) sendLoginReviewRequest {
    [[self tradeSession] asyncAuthenticateAndReviewWithCompletionBlock:^(TradeItResult* result){
        [self loginReviewRequestRecieved: result];
    }];
}

- (void) loginReviewRequestRecieved: (TradeItResult *) result {
    self.lastResult = result;
    
    if ([result isKindOfClass:[TradeItStockOrEtfTradeReviewResult class]]){
        //REVIEW
        self.tradeSession.resultContainer.status = USER_CANCELED;
        self.tradeSession.resultContainer.reviewResponse = (TradeItStockOrEtfTradeReviewResult *) result;
        
        [self setReviewResult:(TradeItStockOrEtfTradeReviewResult *) result];
//        [self performSegueWithIdentifier: @"loadingToReviewSegue" sender: self];
    }
    else if ([result isKindOfClass:[TradeItSecurityQuestionResult class]]){
        self.tradeSession.resultContainer.status = USER_CANCELED_SECURITY;
        
        //SECURITY QUESTION
        TradeItSecurityQuestionResult *securityQuestionResult = (TradeItSecurityQuestionResult *) result;
        
        if (securityQuestionResult.securityQuestionOptions != nil && securityQuestionResult.securityQuestionOptions.count > 0 ){
            //MULTI
            if(![UIAlertController class]) {
//                [self showOldMultiSelect:securityQuestionResult];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Verify Identity"
                                                                                message:securityQuestionResult.securityQuestion
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                
                for(NSString * title in securityQuestionResult.securityQuestionOptions){
                    UIAlertAction * option = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction * action) {
                                                                        [[self tradeSession] asyncAnswerSecurityQuestion:title andCompletionBlock:^(TradeItResult *result) {
                                                                            [self loginReviewRequestRecieved:result];
                                                                        }];
                                                                    }];
                    [alert addAction:option];
                }
                
                UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
//                                                                          [self dismissViewControllerAnimated:YES completion:nil];
                                                                      }];
                [alert addAction:cancelAction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self presentViewController:alert animated:YES completion:nil];
                });
            }
        }
        
        //TODO
        /*
         else if(securityQuestionResult.challengeImage !=nil){
         result = [tradeSession answerSecurityQuestion:@"tradingticket"];
         return processResult(tradeSession, result);
         }
         */
        
        else if (securityQuestionResult.securityQuestion != nil){
            //SINGLE
            if(![UIAlertController class]) {
//                [self showOldSecQuestion: securityQuestionResult.securityQuestion];
            } else {
                UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Security Question"
                                                                                message:securityQuestionResult.securityQuestion
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
//                                                                          [self dismissViewControllerAnimated:YES completion:nil];
                                                                      }];
                UIAlertAction * submitAction = [UIAlertAction actionWithTitle:@"SUBMIT" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          [[self tradeSession] asyncAnswerSecurityQuestion: [[alert textFields][0] text] andCompletionBlock:^(TradeItResult *result) { [self loginReviewRequestRecieved:result]; }];
                                                                      }];
                
                [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {}];
                [alert addAction:cancelAction];
                [alert addAction:submitAction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self presentViewController:alert animated:YES completion:nil];
                });
            }
        }
    } else if([result isKindOfClass:[TradeItMultipleAccountResult class]]){
        //ACCOUNT SELECT
        TradeItMultipleAccountResult * multiAccountResult = (TradeItMultipleAccountResult* ) result;
        
        if(![UIAlertController class]) {
//            [self showOldAcctSelect: multiAccountResult];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Select Account"
                                                                            message:nil
                                                                     preferredStyle:UIAlertControllerStyleActionSheet];
            
            void (^handler)(NSDictionary * account) = ^(NSDictionary * account){
                [[self tradeSession] asyncSelectAccount:account andCompletionBlock:^(TradeItResult *result) {
                    [self loginReviewRequestRecieved:result];
                }];
            };
            
            for (NSDictionary * account in multiAccountResult.accountList) {
                NSString * title = [account objectForKey:@"name"];
                UIAlertAction * acct = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  handler(account);
                                                              }];
                [alert addAction:acct];
            }
            
            UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
//                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            [alert addAction:cancel];
            
            dispatch_async(dispatch_get_main_queue(), ^{
//                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }
    else if([result isKindOfClass:[TradeItErrorResult class]]){
        NSString * errorMessage = @"Could Not Complete Your Order";
        TradeItErrorResult * error = (TradeItErrorResult *) result;
        
        if(error.errorFields.count > 0) {
            NSString * errorField = (NSString *) error.errorFields[0];
            if([errorField isEqualToString:@"authenticationInfo"]) {
                errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
                
                self.tradeSession.resultContainer.status = AUTHENTICATION_ERROR;
                self.tradeSession.resultContainer.errorResponse = error;
            } else {
                errorMessage = error.longMessages.count > 0 ? [[error longMessages] componentsJoinedByString:@" "] : errorMessage;
            }
        }
        
        if(![UIAlertController class]) {
//            [self showOldErrorAlert:@"Could Not Complete Order" withMessage:errorMessage];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                            message:errorMessage
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
//                                                                       [self dismissViewControllerAnimated:YES completion:nil];
                                                                   }];
            [alert addAction:defaultAction];
//            [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        if(![UIAlertController class]) {
//            [self showOldErrorAlert:@"Could Not Complete Order" withMessage:@"TradeIt is temporarily unavailable. Please try again in a few minutes."];
        } else {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                            message:@"TradeIt is temporarily unavailable. Please try again in a few minutes."
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
//                                                                       [self dismissViewControllerAnimated:YES completion:nil];
                                                                   }];
            [alert addAction:defaultAction];
//            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

@end
