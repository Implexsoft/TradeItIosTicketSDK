//
//  TTSDKWebViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 5/2/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKWebViewController.h"

@implementation TTSDKWebViewController


- (IBAction)closePressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) webViewDidStartLoad:(UIWebView *)webView {
    self.navBar.topItem.title = @"Loading...";
}

-(void) webViewDidFinishLoad:(UIWebView *)webView {
    self.navBar.topItem.title = self.pageTitle;
}


@end
