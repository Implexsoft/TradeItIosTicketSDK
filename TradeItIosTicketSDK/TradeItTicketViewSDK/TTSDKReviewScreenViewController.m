//
//  ReviewScreenViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/24/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKReviewScreenViewController.h"
#import "TTSDKPrimaryButton.h"
#import "TTSDKSuccessViewController.h"
#import "TradeItPlaceTradeResult.h"
#import "TTSDKSmallLabel.h"

@interface TTSDKReviewScreenViewController () {
    
    __weak IBOutlet UILabel *reviewLabel;
    __weak IBOutlet TTSDKPrimaryButton *submitOrderButton;
    __weak IBOutlet UIView *contentView;
    __weak IBOutlet UIScrollView *scrollView;

    __weak IBOutlet UIView *accountLabelContainer;
    __weak IBOutlet TTSDKSmallLabel *accountNameLabel;

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
    __weak IBOutlet UIView *warningView;

    //Labels that change
    __weak IBOutlet UILabel *buyingPowerLabel;
    __weak IBOutlet UILabel *estimateCostLabel;
    __weak IBOutlet UILabel *accountLabel;
    __weak IBOutlet UILabel *accountValue;

    //Value Fields
    __weak IBOutlet UILabel *quantityValue;
    __weak IBOutlet UILabel *actionValue;
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

    TradeItPlaceTradeResult * placeTradeResult;
}

@end


static float kMessageSeparatorHeight = -18.0f;


@implementation TTSDKReviewScreenViewController


-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView setAnimationsEnabled:NO];
    [[UIDevice currentDevice] setValue:@1 forKey:@"orientation"];
}

-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [UIView setAnimationsEnabled:YES];
}

-(void) viewDidLoad {
    [super viewDidLoad];

    ackLabels = [[NSMutableArray alloc] init];
    warningLabels = [[NSMutableArray alloc] init];

    // used for attaching constraints
    lastAttachedMessage = accountLabelContainer; //estimatedCostVL

    self.reviewTradeResult = self.ticket.resultContainer.reviewResponse;

    [self updateUIWithReviewResult];

    if ([ackLabels count]) {
        [submitOrderButton deactivate];
        submitOrderButton.enabled = NO;
    } else {
        [submitOrderButton activate];
    }

    scrollView.alwaysBounceHorizontal = NO;
    scrollView.alwaysBounceVertical = YES;

    [self initContentViewHeight];
}

-(void) setViewStyles {
    [super setViewStyles];

    contentView.backgroundColor = self.styles.darkPageBackgroundColor;
    self.view.backgroundColor = self.styles.darkPageBackgroundColor;
}

-(void) updateUIWithReviewResult {
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: US];

    accountNameLabel.text = [self.ticket.currentAccount valueForKey: @"displayTitle"];

    accountLabel.text = [[self.ticket.currentAccount valueForKey: @"broker"] uppercaseString];
    accountValue.text = [self.ticket.currentAccount valueForKey: @"accountNumber"];

    [quantityValue setText:[NSString stringWithFormat:@"%@", [[[self reviewTradeResult] orderDetails] valueForKey:@"orderQuantity"]]];

    NSDictionary * actionOptions = @{
                                     @"buy": @"Buy",
                                     @"sell": @"Sell",
                                     @"buyToCover": @"Buy to Cover",
                                     @"sellShort": @"Sell Short"
                                     };

    if ([actionOptions valueForKey:self.ticket.previewRequest.orderAction] != nil) {
        [actionValue setText: [actionOptions valueForKey:self.ticket.previewRequest.orderAction]];
    } else {
        [actionValue setText: @""];
    }

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
        [buyingPowerLabel setText:@"BUYING POWER"];
        [buyingPowerValue setText:[formatter stringFromNumber: [[[self reviewTradeResult] orderDetails] valueForKey:@"buyingPower"]]];
    } else {
        [buyingPowerLabel setText:@"AVAIL. CASH"];
        [buyingPowerValue setText:[formatter stringFromNumber: [[[self reviewTradeResult] orderDetails] valueForKey:@"availableCash"]]];
    }

    if([[[self reviewTradeResult] orderDetails] valueForKey:@"estimatedOrderCommission"]) {
        [estimatedFeesValue setText:[formatter stringFromNumber: [[[self reviewTradeResult] orderDetails] valueForKey:@"estimatedOrderCommission"]]];
    } else {
        [self hideElement:estimatedFeesVL];
        [self hideElement:estimatedFeesVV];
    }

    if([[[[self reviewTradeResult] orderDetails] valueForKey:@"orderAction"] isEqualToString:@"Sell"] || [[[[self reviewTradeResult] orderDetails] valueForKey:@"orderAction"] isEqualToString:@"Buy to Cover"]) {
        [estimateCostLabel setText:@"ESTIMATED PROCEEDS"];
    } else {
        [estimateCostLabel setText:@"ESTIMATED COST"];
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
    [label setTextColor: self.styles.warningColor];
    [label setFont: [UIFont systemFontOfSize:11]];
    [label setAdjustsFontSizeToFitWidth: NO];

    label.frame = labelFrame;

    [label sizeToFit];

    return label;
}

-(void) addConstraintsToMessage:(UIView *) label {
    NSLayoutConstraint * topConstraint = [NSLayoutConstraint
                                         constraintWithItem:label
                                         attribute:NSLayoutAttributeBottom
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:lastAttachedMessage
                                         attribute:NSLayoutAttributeTop
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
                                           constant:3];
    leftConstraint.priority = 900;

    NSLayoutConstraint * rightConstraint = [NSLayoutConstraint
                                           constraintWithItem:label
                                           attribute:NSLayoutAttributeTrailing
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:contentView
                                           attribute:NSLayoutAttributeTrailingMargin
                                           multiplier:1
                                           constant:-3];
    rightConstraint.priority = 900;

    lastAttachedMessage = label;

    [self.view addConstraint:topConstraint];
    [self.view addConstraint:leftConstraint];
    [self.view addConstraint:rightConstraint];
}

-(void) initContentViewHeight {
    CGRect contentRect = CGRectZero;
    for (UIView * view in [contentView subviews]) {
        CGRect frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height + fabs(kMessageSeparatorHeight));
        contentRect = CGRectUnion(contentRect, frame);
    }

    for(UIView * aLabel in ackLabels) {
        contentRect.size.height += aLabel.frame.size.height;
    }

    for(UILabel * wLabel in warningLabels) {
        contentRect.size.height += wLabel.frame.size.height;
    }

    if (ackLabels.count || warningLabels.count) { // extra padding
        contentRect.size.height += 80;

        if (ackLabels.count) {
            contentRect.size.height += 40;
        }
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
                                             constant:3];
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


#pragma mark Trade Request

-(IBAction) placeOrderPressed:(id)sender {
    [submitOrderButton enterLoadingState];
    [self sendTradeRequest];
}

-(void) sendTradeRequest {
    self.ticket.currentSession.tradeRequest = [[TradeItPlaceTradeRequest alloc] initWithOrderId: self.reviewTradeResult.orderId];

    [self.ticket.currentSession placeTrade:^(TradeItResult *result) {
        [self tradeRequestRecieved: result];
    }];
}

-(void) tradeRequestRecieved: (TradeItResult *) result {
    [submitOrderButton exitLoadingState];
    [submitOrderButton activate];

    //success
    if ([result isKindOfClass: TradeItPlaceTradeResult.class]) {
        self.ticket.resultContainer.status = SUCCESS;
        self.ticket.resultContainer.tradeResponse = (TradeItPlaceTradeResult *) result;
        [self performSegueWithIdentifier:@"ReviewToSuccess" sender: self];
    } else if([result isKindOfClass:[TradeItErrorResult class]]) { //error
        TradeItErrorResult * error = (TradeItErrorResult *) result;

        NSString * errorMessage = @"TradeIt is temporarily unavailable. Please try again in a few minutes.";
        errorMessage = [error.longMessages count] > 0 ? [error.longMessages componentsJoinedByString:@" "] : errorMessage;

        self.ticket.resultContainer.status = EXECUTION_ERROR;
        self.ticket.resultContainer.errorResponse = error;

        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                        message:errorMessage
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        alert.modalPresentationStyle = UIModalPresentationPopover;
        UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                               }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        UIPopoverPresentationController * alertPresentationController = alert.popoverPresentationController;
        alertPresentationController.sourceView = self.view;
        alertPresentationController.permittedArrowDirections = 0;
        alertPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0);
    }
}


#pragma mark Navigation

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
}

-(IBAction) ackLabelToggled:(id)sender {
    UISwitch * switchSender = sender;

    if (switchSender.on) {
        ackLabelsToggled++;
    } else {
        ackLabelsToggled--;
    }

    if (ackLabelsToggled >= [ackLabels count]) {
        [submitOrderButton activate];
        submitOrderButton.enabled = YES;
    } else {
        [submitOrderButton deactivate];
        submitOrderButton.enabled = NO;
    }
}


@end
