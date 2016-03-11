//
//  ReviewScreenViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/24/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKReviewScreenViewController.h"
#import "TTSDKSuccessViewController.h"
#import "TTSDKTradeItTicket.h"
#import "TradeItPlaceTradeResult.h"
#import "TTSDKUtils.h"

@interface TTSDKReviewScreenViewController () {
    
    __weak IBOutlet UILabel *reviewLabel;
    __weak IBOutlet UIButton *submitOrderButton;
    __weak IBOutlet UIView *contentView;
    __weak IBOutlet UIScrollView *scrollView;
    
    //Field Views - needed to set the borders, sometimes collapse
    __weak IBOutlet UIView *quantityVV;
    __weak IBOutlet UIView *quantityVL;
    __weak IBOutlet UIView *priceVV;
    __weak IBOutlet UIView *priceVL;
    __weak IBOutlet UIView *expirationVV;
    __weak IBOutlet UIView *expirationVL;
    __weak IBOutlet UIView *sharesLongVV;
    __weak IBOutlet UIView *sharesLongVL;
    __weak IBOutlet UIView *sharesShortVV;
    __weak IBOutlet UIView *sharesShortVL;
    __weak IBOutlet UIView *buyingPowerVV;
    __weak IBOutlet UIView *buyingPowerVL;
    __weak IBOutlet UIView *estimatedFeesVV;
    __weak IBOutlet UIView *estimatedFeesVL;
    __weak IBOutlet UIView *estimatedCostVV;
    __weak IBOutlet UIView *estimatedCostVL;
    
    //Labels that change
    __weak IBOutlet UILabel *buyingPowerLabel;
    __weak IBOutlet UILabel *estimateCostLabel;
    
    //Value Fields
    __weak IBOutlet UILabel *quantityValue;
    __weak IBOutlet UILabel *priceValue;
    __weak IBOutlet UILabel *expirationValue;
    __weak IBOutlet UILabel *sharesLongValue;
    __weak IBOutlet UILabel *sharesShortValue;
    __weak IBOutlet UILabel *buyingPowerValue;
    __weak IBOutlet UILabel *estimatedFeesValue;
    __weak IBOutlet UILabel *estimatedCostValue;
    
    UIView * lastAttachedMessage;
    NSMutableArray * ackLabels; // used for sizing
    NSMutableArray * warningLabels; // used for sizing

    int ackLabelsToggled;

    TTSDKUtils * utils;
    TTSDKTradeItTicket * globalTicket;

    TradeItPlaceTradeResult * placeTradeResult;
}

@end

static float kMessageSeparatorHeight = 30.0f;

@implementation TTSDKReviewScreenViewController

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    ackLabels = [[NSMutableArray alloc] init];
    warningLabels = [[NSMutableArray alloc] init];

    utils = [TTSDKUtils sharedUtils];
    globalTicket = [TTSDKTradeItTicket globalTicket];

    // used for attaching constraints
    lastAttachedMessage = estimatedCostVL;

    self.reviewTradeResult = globalTicket.resultContainer.reviewResponse;

    [self updateUIWithReviewResult];

    if ([ackLabels count]) {
        [utils styleMainInactiveButton:submitOrderButton];
        submitOrderButton.enabled = NO;
    } else {
        [utils styleMainActiveButton:submitOrderButton];
    }

    scrollView.alwaysBounceHorizontal = NO;
    scrollView.alwaysBounceVertical = YES;

    [self initContentViewHeight];
}

-(void) updateUIWithReviewResult {
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: US];

    [quantityValue setText:[NSString stringWithFormat:@"%@", [[[self reviewTradeResult] orderDetails] valueForKey:@"orderQuantity"]]];
    [priceValue setText:[[[self reviewTradeResult] orderDetails] valueForKey:@"orderPrice"]];
    [expirationValue setText:[[[self reviewTradeResult] orderDetails] valueForKey:@"orderExpiration"]];
    
    if(![[[self reviewTradeResult] orderDetails] valueForKey:@"longHoldings"] || [[[[self reviewTradeResult] orderDetails] valueForKey:@"longHoldings"] isEqualToValue: [NSNumber numberWithDouble:-1]]) {
        [self hideElement:sharesLongVL];
        [self hideElement:sharesLongVV];
    } else {
        [sharesLongValue setText:[NSString stringWithFormat:@"%@", [[[self reviewTradeResult] orderDetails] valueForKey:@"longHoldings"]]];
    }
    
    if(![[[self reviewTradeResult] orderDetails] valueForKey:@"shortHoldings"] || [(NSNumber *)[[[self reviewTradeResult] orderDetails] valueForKey:@"shortHoldings"] isEqualToValue: [NSNumber numberWithDouble:-1]]) {
        [self hideElement:sharesShortVL];
        [self hideElement:sharesShortVV];
    } else {
        [sharesShortValue setText:[NSString stringWithFormat:@"%@", [[[self reviewTradeResult] orderDetails] valueForKey:@"shortHoldings"]]];
    }
    
    if(![[[self reviewTradeResult] orderDetails] valueForKey:@"buyingPower"] && ![[[self reviewTradeResult] orderDetails] valueForKey:@"availableCash"]) {
        [self hideElement:buyingPowerVL];
        [self hideElement:buyingPowerVV];
    } else if ([[[self reviewTradeResult] orderDetails] valueForKey:@"buyingPower"]) {
        [buyingPowerLabel setText:@"Buying Power"];
        [buyingPowerValue setText:[formatter stringFromNumber: [[[self reviewTradeResult] orderDetails] valueForKey:@"buyingPower"]]];
    } else {
        [buyingPowerLabel setText:@"Avail. Cash"];
        [buyingPowerValue setText:[formatter stringFromNumber: [[[self reviewTradeResult] orderDetails] valueForKey:@"availableCash"]]];
    }
    
    if([[[self reviewTradeResult] orderDetails] valueForKey:@"estimatedOrderCommission"]) {
        [estimatedFeesValue setText:[formatter stringFromNumber: [[[self reviewTradeResult] orderDetails] valueForKey:@"estimatedOrderCommission"]]];
    } else {
        [self hideElement:estimatedFeesVL];
        [self hideElement:estimatedFeesVV];
    }
    
    if([[[[self reviewTradeResult] orderDetails] valueForKey:@"orderAction"] isEqualToString:@"Sell"] || [[[[self reviewTradeResult] orderDetails] valueForKey:@"orderAction"] isEqualToString:@"Buy to Cover"]) {
        [estimateCostLabel setText:@"Estimated Proceeds"];
    } else {
        [estimateCostLabel setText:@"Estimated Cost"];
    }
    
    if([[[self reviewTradeResult] orderDetails] valueForKey:@"estimatedOrderValue"]) {
        [estimatedCostValue setText:[formatter stringFromNumber: [[[self reviewTradeResult] orderDetails] valueForKey:@"estimatedOrderValue"]]];
    } else {
        [estimatedCostValue setText:[formatter stringFromNumber: [[[self reviewTradeResult] orderDetails] valueForKey:@"estimatedTotalValue"]]];
    }
    
    for(NSString * warning in [[self reviewTradeResult] warningsList]) {
        [self addReviewMessage: warning];
    }
    
    for(NSString * warning in [[self reviewTradeResult] ackWarningsList]) {
        [self addAcknowledgeMessage: warning];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) hideElement:(UIView *) element {
    NSLayoutConstraint * heightConstraint = [NSLayoutConstraint
                                            constraintWithItem:element
                                            attribute:NSLayoutAttributeHeight
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:NSLayoutAttributeNotAnAttribute
                                            attribute:NSLayoutAttributeNotAnAttribute
                                            multiplier:1
                                            constant:1];
    heightConstraint.priority = 900;

    [self.view addConstraint:heightConstraint];
}

-(void) addReviewMessage:(NSString *) message {
    UILabel * messageLabel = [self createAndSizeMessageUILabel:message];
    messageLabel.autoresizesSubviews = YES;
    [contentView insertSubview:messageLabel atIndex:0];
    [self addConstraintsToMessage:messageLabel];

    [warningLabels addObject:messageLabel];
}

-(void) addAcknowledgeMessage:(NSString *) message {
    UIView * container = [[UIView alloc] init];
    [container setTranslatesAutoresizingMaskIntoConstraints:NO];

    UISwitch * toggle = [[UISwitch alloc] init];
    UILabel * messageLabel = [self createAndSizeMessageUILabel:message];
    toggle.autoresizesSubviews = YES;
    messageLabel.autoresizesSubviews = YES;

    toggle.userInteractionEnabled = YES;

    [toggle addTarget:self action:@selector(ackLabelToggled:) forControlEvents:UIControlEventValueChanged];

    [ackLabels addObject:messageLabel];
    
    [container addSubview:toggle];
    [container addSubview:messageLabel];
    [contentView insertSubview:container atIndex:0];
    
    [self constrainToggle:toggle andLabel:messageLabel toView:container];
    [self addConstraintsToMessage:container];
}



-(UILabel *) createAndSizeMessageUILabel: (NSString *) message {
    CGRect labelFrame = reviewLabel.frame;
    labelFrame.size.width = contentView.frame.size.width;

    UILabel * label = [[UILabel alloc] init];
    [label setText: message];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    [label setTranslatesAutoresizingMaskIntoConstraints: NO];
    [label setNumberOfLines: 0]; // 0 allows unlimited lines
    [label setTextColor: utils.warningColor];
    [label setFont: [UIFont systemFontOfSize:11]];
    [label setAdjustsFontSizeToFitWidth: NO];

    label.frame = labelFrame;

    [label sizeToFit];

    return label;
}

-(void) addConstraintsToMessage:(UIView *) label {
    NSLayoutConstraint * topConstraint = [NSLayoutConstraint
                                         constraintWithItem:label
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:lastAttachedMessage
                                         attribute:NSLayoutAttributeBottom
                                         multiplier:1
                                         constant:kMessageSeparatorHeight];
    topConstraint.priority = 900;

    NSLayoutConstraint * leftConstraint = [NSLayoutConstraint
                                           constraintWithItem:label
                                           attribute:NSLayoutAttributeLeading
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:contentView
                                           attribute:NSLayoutAttributeLeadingMargin
                                           multiplier:1
                                           constant:0];
    leftConstraint.priority = 900;

    NSLayoutConstraint * rightConstraint = [NSLayoutConstraint
                                           constraintWithItem:label
                                           attribute:NSLayoutAttributeTrailing
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:contentView
                                           attribute:NSLayoutAttributeTrailingMargin
                                           multiplier:1
                                           constant:0];
    rightConstraint.priority = 900;

    lastAttachedMessage = label;

    [self.view addConstraint:topConstraint];
    [self.view addConstraint:leftConstraint];
    [self.view addConstraint:rightConstraint];
}

-(void) initContentViewHeight {
    CGRect contentRect = CGRectZero;
    for (UIView * view in [contentView subviews]) {
        CGRect frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height + kMessageSeparatorHeight);
        contentRect = CGRectUnion(contentRect, frame);
    }

    for(UIView * aLabel in ackLabels) {
        contentRect.size.height += aLabel.frame.size.height;
    }

    for(UILabel * wLabel in warningLabels) {
        contentRect.size.height += wLabel.frame.size.height;
    }

    if (ackLabels.count || warningLabels.count) {
        contentRect.size.height += 80; // extra padding
    }

    NSLayoutConstraint * heightConstraint = [NSLayoutConstraint
                                             constraintWithItem:contentView
                                             attribute:NSLayoutAttributeHeight
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:NSLayoutAttributeNotAnAttribute
                                             attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1
                                             constant:contentRect.size.height];
    heightConstraint.priority = 900;
    [self.view addConstraint:heightConstraint];

    [scrollView setContentSize:contentRect.size];
    [scrollView layoutIfNeeded];
    [scrollView setNeedsUpdateConstraints];

    // Remove scrolling capabilities if there's no need to scroll
    if (scrollView.frame.size.height >= scrollView.contentSize.height) {
        scrollView.scrollEnabled = NO;
        scrollView.bounces = NO;
    }
}

-(void) constrainToggle:(UISwitch *) toggle andLabel:(UILabel *) label toView:(UIView *) view {
    NSLayoutConstraint * toggleLeftConstraint = [NSLayoutConstraint
                                             constraintWithItem:toggle
                                             attribute:NSLayoutAttributeLeading
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:view
                                             attribute:NSLayoutAttributeLeading
                                             multiplier:1
                                             constant:0];
    toggleLeftConstraint.priority = 900;
    
    NSLayoutConstraint * toggleTopConstraint = [NSLayoutConstraint
                                                 constraintWithItem:toggle
                                                 attribute:NSLayoutAttributeTop
                                                 relatedBy:NSLayoutRelationEqual
                                                 toItem:view
                                                 attribute:NSLayoutAttributeTop
                                                 multiplier:1
                                                 constant:0];
    toggleTopConstraint.priority = 900;

    NSLayoutConstraint * toggleLabelConstraint = [NSLayoutConstraint
                                                constraintWithItem:toggle
                                                attribute:NSLayoutAttributeTrailing
                                                relatedBy:NSLayoutRelationEqual
                                                toItem:label
                                                attribute:NSLayoutAttributeLeading
                                                multiplier:1
                                                constant:-10];
    toggleLabelConstraint.priority = 900;

    NSLayoutConstraint * labelTopConstraint = [NSLayoutConstraint
                                                  constraintWithItem:label
                                                  attribute:NSLayoutAttributeTop
                                                  relatedBy:NSLayoutRelationEqual
                                                  toItem:view
                                                  attribute:NSLayoutAttributeTop
                                                  multiplier:1
                                                  constant:0];
    labelTopConstraint.priority = 900;
    
    NSLayoutConstraint * labelRightConstraint = [NSLayoutConstraint
                                               constraintWithItem:label
                                               attribute:NSLayoutAttributeTrailing
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:view
                                               attribute:NSLayoutAttributeTrailing
                                               multiplier:1
                                               constant:0];
    labelRightConstraint.priority = 900;
    
    NSLayoutConstraint * labelBottomConstraint = [NSLayoutConstraint
                                                  constraintWithItem:label
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                  toItem:view
                                                  attribute:NSLayoutAttributeBottom
                                                  multiplier:1
                                                  constant:0];
    labelBottomConstraint.priority = 900;
    
    
    [self.view addConstraint:toggleLeftConstraint];
    [self.view addConstraint:toggleTopConstraint];
    [self.view addConstraint:toggleLabelConstraint];
    [self.view addConstraint:labelTopConstraint];
    [self.view addConstraint:labelRightConstraint];
    [self.view addConstraint:labelBottomConstraint];
}


#pragma mark - Trade Request
- (IBAction)placeOrderPressed:(id)sender {
    [utils styleLoadingButton:submitOrderButton];
    [self sendTradeRequest];
}

- (void) sendTradeRequest {

    globalTicket.currentSession.tradeRequest = [[TradeItPlaceTradeRequest alloc] initWithOrderId: self.reviewTradeResult.orderId];

    [globalTicket.currentSession placeTrade:^(TradeItResult *result) {
        [self tradeRequestRecieved: result];
    }];
}

- (void) tradeRequestRecieved: (TradeItResult *) result {
    [utils styleMainActiveButton:submitOrderButton];

    //success
    if ([result isKindOfClass: TradeItPlaceTradeResult.class]) {
        globalTicket.resultContainer.status = SUCCESS;
        globalTicket.resultContainer.tradeResponse = (TradeItPlaceTradeResult *) result;
        [self performSegueWithIdentifier:@"ReviewToSuccess" sender: self];
    }
    //error
    if([result isKindOfClass:[TradeItErrorResult class]]) {
        TradeItErrorResult * error = (TradeItErrorResult *) result;

        NSString * errorMessage = @"TradeIt is temporarily unavailable. Please try again in a few minutes.";
        errorMessage = [error.longMessages count] > 0 ? [error.longMessages componentsJoinedByString:@" "] : errorMessage;

        globalTicket.resultContainer.status = EXECUTION_ERROR;
        globalTicket.resultContainer.errorResponse = error;

        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                        message:errorMessage
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        alert.modalPresentationStyle = UIModalPresentationPopover;
        UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   [self dismissViewControllerAnimated:YES completion:nil];
                                                               }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
        alertPresentationController.sourceView = self.view;
        alertPresentationController.permittedArrowDirections = 0;
        alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
    }
}



#pragma mark - Navigation

-(IBAction)ackLabelToggled:(id)sender {
    UISwitch * switchSender = sender;

    if (switchSender.on) {
        ackLabelsToggled++;
    } else {
        ackLabelsToggled--;
    }

    if (ackLabelsToggled >= [ackLabels count]) {
        [utils styleMainActiveButton:submitOrderButton];
        submitOrderButton.enabled = YES;
    } else {
        [utils styleMainInactiveButton: submitOrderButton];
        submitOrderButton.enabled = NO;
    }
}



@end
