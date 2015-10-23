//
//  ReviewScreenViewController.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/24/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TTSDKReviewScreenViewController.h"

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
    NSMutableArray * ackLabels; //used for sizing
}

@end

@implementation TTSDKReviewScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    ackLabels = [[NSMutableArray alloc]init];
    
    [self setBackgroundGradient];
    [self setTableBorders];
    [submitOrderButton.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [submitOrderButton.layer setBorderWidth:1.0f];
    [submitOrderButton.layer setCornerRadius:5.0f];
    
    //used for attaching constraints
    lastAttachedMessage = estimatedCostVL;
    
    [self updateUIWithReviewResult];
    [self setContentViewHeight];
}

-(void) updateUIWithReviewResult {
    NSLocale * US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale: US];
    
    [reviewLabel setText:[[[self result] orderDetails] valueForKey:@"orderMessage"]];
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

- (void) setBackgroundGradient {
    UIColor *topColor = [UIColor colorWithRed:48.0f/255.0f green:104.0f/255.0f blue:155.0f/255.0f alpha:1.0f];
    UIColor *bottomColor = [UIColor colorWithRed:8.0f/255.0f green:65.0f/255.0f blue:106.0f/255.0f alpha:1.0f];
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
    NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.locations = gradientLocations;
    gradientLayer.frame = self.view.frame;
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
}

- (void) setTableBorders {
    [priceVV.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [priceVL.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [quantityVV.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [quantityVL.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [expirationVV.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [expirationVL.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [sharesLongVV.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [sharesLongVL.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [sharesShortVV.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [sharesShortVL.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [buyingPowerVV.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [buyingPowerVL.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [estimatedFeesVV.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [estimatedFeesVL.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [estimatedCostVV.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    [estimatedCostVL.layer setBorderColor:[[UIColor whiteColor]CGColor]];
    
    [priceVV.layer setBorderWidth:1.0f];
    [priceVL.layer setBorderWidth:1.0f];
    [quantityVV.layer setBorderWidth:1.0f];
    [quantityVL.layer setBorderWidth:1.0f];
    [expirationVV.layer setBorderWidth:1.0f];
    [expirationVL.layer setBorderWidth:1.0f];
    [sharesLongVV.layer setBorderWidth:1.0f];
    [sharesLongVL.layer setBorderWidth:1.0f];
    [sharesShortVV.layer setBorderWidth:1.0f];
    [sharesShortVL.layer setBorderWidth:1.0f];
    [buyingPowerVV.layer setBorderWidth:1.0f];
    [buyingPowerVL.layer setBorderWidth:1.0f];
    [estimatedFeesVV.layer setBorderWidth:1.0f];
    [estimatedFeesVL.layer setBorderWidth:1.0f];
    [estimatedCostVV.layer setBorderWidth:1.0f];
    [estimatedCostVL.layer setBorderWidth:1.0f];
}

-(void) addReviewMessage:(NSString *) message {

    UILabel * messageLabel = [self createAndSizeMessageUILabel:message];
    [contentView addSubview:messageLabel];
    [self addConstraintsToMessage:messageLabel];
}

-(void) addAcknowledgeMessage:(NSString *) message {
    UIView * container = [[UIView alloc] init];
    [container setTranslatesAutoresizingMaskIntoConstraints:NO];

    UISwitch * toggle = [[UISwitch alloc] init];
    UILabel * messageLabel = [self createAndSizeMessageUILabel:message];

    [ackLabels addObject:messageLabel];
    
    [container addSubview:toggle];
    [container addSubview:messageLabel];
    [contentView addSubview:container];
    
    [self constrainToggle:toggle andLabel:messageLabel toView:container];
    [self addConstraintsToMessage:container];
}

-(UILabel *) createAndSizeMessageUILabel: (NSString *) message {
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, reviewLabel.frame.size.width, CGFLOAT_MAX)];
    [label setTranslatesAutoresizingMaskIntoConstraints: NO];
    [label setText: message];
    [label setNumberOfLines: 0]; //0 allows unlimited lines
    [label setTextColor: [UIColor whiteColor]];
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
                                         constant:10];
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
        if(!(view.tag > 400 && view.tag < 409)) { //These are the label views, we don't count them since we count the value side
            scrollViewHeight += view.frame.size.height;
        }
    }
    
    for(UIView * label in ackLabels) {
        scrollViewHeight += label.frame.size.height;
    }
    
    NSLayoutConstraint * heightConstraint = [NSLayoutConstraint
                                             constraintWithItem:contentView
                                             attribute:NSLayoutAttributeHeight
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:NSLayoutAttributeNotAnAttribute
                                             attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1
                                             constant:scrollViewHeight + 30]; //extra 30 for padding
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([segue.identifier isEqualToString:@"reviewToLoadingSegue"]) {
        [[segue destinationViewController] setActionToPerform: @"sendTradeRequest"];
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


@end












