//
//  TTSDKViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 4/6/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKViewController.h"

@interface TTSDKViewController()
    @property (copy) void (^acceptanceBlock)();
@end

@implementation TTSDKViewController


#pragma mark Rotation

-(BOOL) shouldAutorotate {
    return NO;
}

-(UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

-(UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark Initialization

-(void) viewDidLoad {
    self.ticket = [TTSDKTradeItTicket globalTicket];
    self.utils = [TTSDKUtils sharedUtils];
    self.styles = [TradeItStyles sharedStyles];

    [super viewDidLoad];

    [self setViewStyles];
}

-(void) setViewStyles {
    self.view.backgroundColor = self.styles.pageBackgroundColor;

    if (self.styles.navigationBarTitleColor) {
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : self.styles.navigationBarTitleColor}];
    }
    self.navigationController.navigationBar.barTintColor = self.styles.navigationBarBackgroundColor;
    self.navigationController.navigationBar.tintColor = self.styles.activeColor;
}


#pragma mark Picker

-(NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pickerTitles.count;
}

-(NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.pickerTitles[row];
}

-(void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.currentSelection = self.pickerValues[row];
}

-(void) showPicker:(NSString *)pickerTitle withSelection:(NSString *)selection andOptions:(NSArray *)options onSelection:(void (^)(void))selectionBlock {
    self.currentSelection = selection;

    if(![UIAlertController class]) {
        NSMutableArray * titles = [[NSMutableArray alloc] init];
        NSMutableArray * values = [[NSMutableArray alloc] init];

        for (NSDictionary *optionContainer in options) {
            NSString * k = [optionContainer.allKeys firstObject];
            NSString * v = optionContainer[k];
            [titles addObject: k];
            [values addObject: v];
        }

        self.pickerTitles = [titles copy];
        self.pickerValues = [values copy];

        TTSDKCustomIOSAlertView * alert = [[TTSDKCustomIOSAlertView alloc]init];
        [alert setContainerView:[self createPickerView: pickerTitle]];
        [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"CANCEL",@"SELECT",nil]];
        
        [alert setOnButtonTouchUpInside:^(TTSDKCustomIOSAlertView *alertView, int buttonIndex) {
            if(buttonIndex == 1) {
                selectionBlock();
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
    } else {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:pickerTitle
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
        alert.modalPresentationStyle = UIModalPresentationPopover;
        alert.view.tintColor = self.styles.activeColor;

        for (NSDictionary *optionContainer in options) {
            NSString * k = [optionContainer.allKeys firstObject];
            NSString * v = optionContainer[k];

            UIAlertAction * action = [UIAlertAction actionWithTitle:k style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                self.currentSelection = v;
                selectionBlock();
            }];

            [alert addAction: action];
        }

        UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            // do nothing
        }];
        [alert addAction: cancelAction];

        [self presentViewController:alert animated:YES completion:nil];

        UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
        alertPresentationController.sourceView = self.view;
        alertPresentationController.permittedArrowDirections = 0;
        alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
    }
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
    self.currentPicker = picker;
    
    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [contentView addSubview:picker];
    
    [contentView setNeedsDisplay];
    return contentView;
}


#pragma mark Alert Delegate Methods

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.acceptanceBlock) {
        self.acceptanceBlock();
    }
}


#pragma mark iOS7 fallbacks

-(void) showErrorAlert:(TradeItErrorResult *)error onAccept:(void (^)(void))acceptanceBlock {
    NSMutableString * errorMessage = [[NSMutableString alloc] init];

    for (NSString * str in error.longMessages) {
        [errorMessage appendString:str];
    }

    self.acceptanceBlock = acceptanceBlock;

    if(![UIAlertController class]) {
        [self showOldErrorAlert:error.shortMessage withMessage:errorMessage];
    } else {
        
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:error.shortMessage
                                                                        message:errorMessage
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        
        alert.modalPresentationStyle = UIModalPresentationPopover;

        UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   self.acceptanceBlock();
                                                               }];

        UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            // do nothing
        }];
        
        [alert addAction:defaultAction];
        [alert addAction:cancelAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        
        UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
        alertPresentationController.sourceView = self.view;
        alertPresentationController.permittedArrowDirections = 0;
        alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
    }
}

-(void) showOldErrorAlert: (NSString *) title withMessage:(NSString *) message {
    UIAlertView * alert;
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}


@end