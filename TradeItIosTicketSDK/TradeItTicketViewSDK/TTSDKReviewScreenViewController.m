//
//  ReviewScreenViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/24/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKReviewScreenViewController.h"
#import "TTSDKHelper.h"

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

    TTSDKHelper * helper;
}

@end

@implementation TTSDKReviewScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    ackLabels = [[NSMutableArray alloc] init];
    warningLabels = [[NSMutableArray alloc] init];

    helper = [TTSDKHelper sharedHelper];

    // used for attaching constraints
    lastAttachedMessage = estimatedCostVL;

    [self updateUIWithReviewResult];

    if ([ackLabels count]) {
        [helper styleMainInactiveButton:submitOrderButton];
        submitOrderButton.enabled = NO;
    } else {
        [helper styleMainActiveButton:submitOrderButton];
    }

    [self setContentViewHeight];
}

-(void) updateUIWithReviewResult {
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: US];

    [quantityValue setText:[NSString stringWithFormat:@"%@", [[[self result] orderDetails] valueForKey:@"orderQuantity"]]];
    [priceValue setText:[[[self result] orderDetails] valueForKey:@"orderPrice"]];
    [expirationValue setText:[[[self result] orderDetails] valueForKey:@"orderExpiration"]];
    
    if(![[[self result] orderDetails] valueForKey:@"longHoldings"] || [[[[self result] orderDetails] valueForKey:@"longHoldings"] isEqualToValue: [NSNumber numberWithDouble:-1]]) {
        [self hideElement:sharesLongVL];
        [self hideElement:sharesLongVV];
    } else {
        [sharesLongValue setText:[NSString stringWithFormat:@"%@", [[[self result] orderDetails] valueForKey:@"longHoldings"]]];
    }
    
    if(![[[self result] orderDetails] valueForKey:@"shortHoldings"] || [(NSNumber *)[[[self result] orderDetails] valueForKey:@"shortHoldings"] isEqualToValue: [NSNumber numberWithDouble:-1]]) {
        [self hideElement:sharesShortVL];
        [self hideElement:sharesShortVV];
    } else {
        [sharesShortValue setText:[NSString stringWithFormat:@"%@", [[[self result] orderDetails] valueForKey:@"shortHoldings"]]];
    }
    
    if(![[[self result] orderDetails] valueForKey:@"buyingPower"] && ![[[self result] orderDetails] valueForKey:@"availableCash"]) {
        [self hideElement:buyingPowerVL];
        [self hideElement:buyingPowerVV];
    } else if ([[[self result] orderDetails] valueForKey:@"buyingPower"]) {
        [buyingPowerLabel setText:@"Buying Power"];
        [buyingPowerValue setText:[formatter stringFromNumber: [[[self result] orderDetails] valueForKey:@"buyingPower"]]];
    } else {
        [buyingPowerLabel setText:@"Avail. Cash"];
        [buyingPowerValue setText:[formatter stringFromNumber: [[[self result] orderDetails] valueForKey:@"availableCash"]]];
    }
    
    if([[[self result] orderDetails] valueForKey:@"estimatedOrderCommission"]) {
        [estimatedFeesValue setText:[formatter stringFromNumber: [[[self result] orderDetails] valueForKey:@"estimatedOrderCommission"]]];
    } else {
        [self hideElement:estimatedFeesVL];
        [self hideElement:estimatedFeesVV];
    }
    
    if([[[[self result] orderDetails] valueForKey:@"orderAction"] isEqualToString:@"Sell"] || [[[[self result] orderDetails] valueForKey:@"orderAction"] isEqualToString:@"Buy to Cover"]) {
        [estimateCostLabel setText:@"Estimated Proceeds"];
    } else {
        [estimateCostLabel setText:@"Estimated Cost"];
    }
    
    if([[[self result] orderDetails] valueForKey:@"estimatedOrderValue"]) {
        [estimatedCostValue setText:[formatter stringFromNumber: [[[self result] orderDetails] valueForKey:@"estimatedOrderValue"]]];
    } else {
        [estimatedCostValue setText:[formatter stringFromNumber: [[[self result] orderDetails] valueForKey:@"estimatedTotalValue"]]];
    }
    
    for(NSString * warning in [[self result] warningsList]) {
        [self addReviewMessage: warning];
    }
    
    for(NSString * warning in [[self result] ackWarningsList]) {
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
    [contentView insertSubview:messageLabel atIndex:0];
    [self addConstraintsToMessage:messageLabel];

    [warningLabels addObject:messageLabel];
}

-(void) addAcknowledgeMessage:(NSString *) message {
    UIView * container = [[UIView alloc] init];
    [container setTranslatesAutoresizingMaskIntoConstraints:NO];

    UISwitch * toggle = [[UISwitch alloc] init];
    UILabel * messageLabel = [self createAndSizeMessageUILabel:message];

    toggle.userInteractionEnabled = YES;

    [toggle addTarget:self action:@selector(ackLabelToggled:) forControlEvents:UIControlEventValueChanged];

//    [toggle addGestureRecognizer:gestureRec];

    [ackLabels addObject:messageLabel];
    
    [container addSubview:toggle];
    [container addSubview:messageLabel];
    [contentView insertSubview:container atIndex:0];
    
    [self constrainToggle:toggle andLabel:messageLabel toView:container];
    [self addConstraintsToMessage:container];
}



-(UILabel *) createAndSizeMessageUILabel: (NSString *) message {
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, reviewLabel.frame.size.width, CGFLOAT_MAX)];
    [label setTranslatesAutoresizingMaskIntoConstraints: NO];
    [label setText: message];
    [label setNumberOfLines: 0]; // 0 allows unlimited lines
    [label setTextColor: helper.warningColor];
    [label setFont: [UIFont systemFontOfSize:11]];
    [label setAdjustsFontSizeToFitWidth: NO];
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
                                         constant:30];
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

-(void) setContentViewHeight {
    CGFloat scrollViewHeight = 0.0f;
    for (UIView* view in contentView.subviews)
    {
        if(!(view.tag > 400 && view.tag < 409)) { // These are the label views, we don't count them since we count the value side
            scrollViewHeight += view.frame.size.height;
        }
    }

    for(UIView * label in ackLabels) {
        scrollViewHeight += label.frame.size.height;
    }

    for(UILabel * wLabel in warningLabels) {
        scrollViewHeight += wLabel.frame.size.height;
    }

    NSLayoutConstraint * heightConstraint = [NSLayoutConstraint
                                             constraintWithItem:contentView
                                             attribute:NSLayoutAttributeHeight
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:NSLayoutAttributeNotAnAttribute
                                             attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1
                                             constant:scrollViewHeight + 100]; // extra 30 for padding
    heightConstraint.priority = 900;
    [self.view addConstraint:heightConstraint];
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
    [helper styleLoadingButton:submitOrderButton];
    [self sendTradeRequest];
}

- (void) sendTradeRequest {
    [[self tradeSession] asyncPlaceOrderWithCompletionBlock:^(TradeItResult *result) {
        [self tradeRequestRecieved:result];
    }];
}

- (void) tradeRequestRecieved: (TradeItResult *) result {
    [helper styleMainActiveButton:submitOrderButton];

    //success
    if([result isKindOfClass:[TradeItStockOrEtfTradeSuccessResult class]]){
        self.tradeSession.resultContainer.status = SUCCESS;
        self.tradeSession.resultContainer.successResponse = (TradeItStockOrEtfTradeSuccessResult *) result;
        
        [self setSuccessResult:(TradeItStockOrEtfTradeSuccessResult *) result];
        [self performSegueWithIdentifier: @"ReviewToSuccess" sender: self];
    }
    //error
    else if([result isKindOfClass:[TradeItErrorResult class]]) {
        TradeItErrorResult * error = (TradeItErrorResult *) result;
        
        NSString * errorMessage = @"TradeIt is temporarily unavailable. Please try again in a few minutes.";
        errorMessage = [error.longMessages count] > 0 ? [error.longMessages componentsJoinedByString:@" "] : errorMessage;
        
        self.tradeSession.resultContainer.status = EXECUTION_ERROR;
        self.tradeSession.resultContainer.errorResponse = error;
        
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Could Not Complete Order"
                                                                        message:errorMessage
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   [self dismissViewControllerAnimated:YES completion:nil];
                                                               }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([segue.identifier isEqualToString:@"reviewToLoadingSegue"]) {
        [[segue destinationViewController] setActionToPerform: @"sendTradeRequest"];
        [[segue destinationViewController] setTradeSession: self.tradeSession];
    } else if ([segue.identifier isEqualToString:@"ReviewToSuccess"]) {
        [[segue destinationViewController] setResult: self.successResult];
        [[segue destinationViewController] setTradeSession: self.tradeSession];
    }
}

- (IBAction)changeClicked:(id)sender {
    if([self.tradeSession.calcScreenStoryboardId isEqualToString:@"initalCalculatorController"]) {
        [self performSegueWithIdentifier:@"prepareForUnwind" sender:self];
    } else {
        [self performSegueWithIdentifier:@"unwindToAdvCalc" sender:self];
    }
}

- (IBAction)cancelPressed:(id)sender {
    [TTSDKTradeItTicket returnToParentApp:self.tradeSession];
}

-(IBAction)ackLabelToggled:(id)sender {
    UISwitch * switchSender = sender;

    if (switchSender.on) {
        ackLabelsToggled++;
    }

    if (ackLabelsToggled >= [ackLabels count]) {
        [helper styleMainActiveButton:submitOrderButton];
        submitOrderButton.enabled = YES;
    }
}

@end












