//
//  TTSDKBrokerCenterTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 5/9/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKBrokerCenterTableViewCell.h"
#import "TTSDKTradeItTicket.h"
#import "TTSDKAttributedLabel.h"
//#import "<CoreText/CTStringAttributes.h>"

@interface TTSDKBrokerCenterTableViewCell()

@property TradeItBrokerCenterBroker * data;
@property TTSDKTradeItTicket * ticket;

@property NSArray * disclaimerLabels;

@property UILabel * lastAttachedMessage;
@property (weak, nonatomic) IBOutlet UIButton *toggleExpanded;
@property (weak, nonatomic) IBOutlet UILabel *offerTitle;
@property (weak, nonatomic) IBOutlet UILabel *offerDescription;
@property (weak, nonatomic) IBOutlet UILabel *accountMinimum;
@property (weak, nonatomic) IBOutlet UILabel *optionsOffer;
@property (weak, nonatomic) IBOutlet UILabel *stocksEtfsOffer;
@property (weak, nonatomic) IBOutlet UIButton *callToActionButton;
@property (weak, nonatomic) IBOutlet UIImageView *detailsArrow;
@property (weak, nonatomic) IBOutlet UILabel *optionsTitle;
@property (weak, nonatomic) IBOutlet UILabel *stocksEtfsTitle;
@property (weak, nonatomic) IBOutlet UILabel *featuresTitle;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot1;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot2;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot3;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot4;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot5;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot6;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot7;
@property (weak, nonatomic) IBOutlet UILabel *featureSlot8;
@property (weak, nonatomic) IBOutlet UIImageView *logo;
@property (weak, nonatomic) IBOutlet UILabel *logoLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoWidthConstraint;
@property (weak, nonatomic) IBOutlet UIButton *disclaimerButton;
@property (weak, nonatomic) IBOutlet UIView *disclaimerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *disclaimerHeightConstraint;

@end

@implementation TTSDKBrokerCenterTableViewCell

static float kMessageSeparatorHeight = 10.0f;

#pragma Mark Class methods

+(UIColor *) colorFromArray:(NSArray *)colorArray {
    NSNumber * red = [colorArray objectAtIndex:0];
    NSNumber * green = [colorArray objectAtIndex:1];
    NSNumber * blue = [colorArray objectAtIndex:2];
    NSNumber * alpha;
    
    if (colorArray.count > 3) {
        alpha = [colorArray objectAtIndex:3];
    } else {
        alpha = @1.0;
    }
    
    UIColor * color = [UIColor colorWithRed: [red floatValue]/255.0f  green:[green floatValue]/255.0f blue:[blue floatValue]/255.0f alpha:[alpha floatValue]];
    
    return color;
}


#pragma Mark Initialization

-(void) awakeFromNib {
    self.ticket = [TTSDKTradeItTicket globalTicket];
}

-(void) configureWithBroker:(TradeItBrokerCenterBroker *)broker {
    self.data = broker;

    [self populateSignupOffer];

    [self populateAccountMinimum];

    [self populateOptionsOffer];

    [self populateStocksEtfsOffer];

    [self populateFeatures: broker.features];

    [self.callToActionButton setTitle:@"Open an Account" forState:UIControlStateNormal];

    self.disclaimerLabels = [[NSArray alloc] init];

    [self populateDisclaimers];

    self.disclaimerLabelsTotalHeight = 0.0f;
    for (UILabel *label in self.disclaimerLabels) {
        self.disclaimerLabelsTotalHeight += label.frame.size.height;
    }

    if (self.disclaimerToggled) {
        [self.disclaimerButton setTitle:@"CLOSE" forState:UIControlStateNormal];
        self.disclaimerHeightConstraint.constant = self.disclaimerLabelsTotalHeight;
    } else {
        [self.disclaimerButton setTitle:@"DISCLAIMER" forState:UIControlStateNormal];
        self.disclaimerHeightConstraint.constant = 0.0f;
    }

    [self populateStyles];
}


#pragma Mark Custom Styles

-(void) populateStyles {
    // SET COLORS
    
    UIColor * backgroundColor = [TTSDKBrokerCenterTableViewCell colorFromArray: self.data.backgroundColor];
    
    self.contentView.backgroundColor = backgroundColor;
    self.backgroundColor = backgroundColor;
    
    UIColor * textColor = [TTSDKBrokerCenterTableViewCell colorFromArray: self.data.textColor];
    
    self.offerTitle.textColor = textColor;
    self.offerDescription.textColor = textColor;
    self.accountMinimum.textColor = textColor;
    self.optionsOffer.textColor = textColor;
    self.optionsTitle.textColor = textColor;
    self.stocksEtfsOffer.textColor = textColor;
    self.stocksEtfsTitle.textColor = textColor;
    [self.callToActionButton setTitleColor:textColor forState:UIControlStateNormal];
    self.detailsArrow.image = [self.detailsArrow.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.detailsArrow.tintColor = textColor;
    self.featuresTitle.textColor = textColor;
    self.featureSlot1.textColor = textColor;
    self.featureSlot2.textColor = textColor;
    self.featureSlot3.textColor = textColor;
    self.featureSlot4.textColor = textColor;
    self.featureSlot5.textColor = textColor;
    self.featureSlot6.textColor = textColor;
    self.featureSlot7.textColor = textColor;
    self.featureSlot8.textColor = textColor;
    self.logoLabel.textColor = textColor;
    [self.disclaimerButton setTitleColor:textColor forState:UIControlStateNormal];
    
    UIColor * buttonBackgroundColor = [TTSDKBrokerCenterTableViewCell colorFromArray: self.data.promptBackgroundColor];
    [self.callToActionButton setTitleColor:[TTSDKBrokerCenterTableViewCell colorFromArray:self.data.promptTextColor] forState:UIControlStateNormal];
    self.callToActionButton.backgroundColor = buttonBackgroundColor;
    self.callToActionButton.layer.cornerRadius = 5.0f;
}

-(void) addImage:(UIImage *)img {
    if (img) {
        self.logoLabel.hidden = YES;
        self.logoLabel.text = @"";

        self.logo.image = img;
        [self.logo layoutSubviews];
        
        // we need to determine the actual scale factor the image will use and then set the height constraint appropriately
        float scaleFactor = self.logoWidthConstraint.constant / img.size.width;
        float imageHeight = img.size.height * scaleFactor;
        self.logoHeightConstraint.constant = imageHeight;

    } else {
        self.logo.image = nil;
        self.logoLabel.hidden = NO;
        self.logoLabel.text = [self.ticket getBrokerDisplayString: self.data.broker];
    }
}

-(void) configureSelectedState:(BOOL)selected {
    if (selected) {
        self.detailsArrow.hidden = YES;
    } else {
        self.detailsArrow.hidden = NO;
    }
}

-(void) configureDisclaimers:(UIView *)disclaimerView {
    NSLog(@"CONFIGURING DISCLAIMER FOR %@", self.data.broker);

    for (UIView *subview in self.disclaimerView.subviews) {
        [subview removeFromSuperview];
    }

    NSLog(@"SETTING CONTAINER HEIGHT CONSTANT: %f", self.disclaimerLabelsTotalHeight);
    self.disclaimerHeightConstraint.constant = self.disclaimerLabelsTotalHeight;

    [self.disclaimerView addSubview: disclaimerView];

    NSLayoutConstraint * topConstraint = [NSLayoutConstraint
                                          constraintWithItem:disclaimerView
                                          attribute:NSLayoutAttributeTop
                                          relatedBy:NSLayoutRelationEqual
                                          toItem:self.disclaimerView
                                          attribute:NSLayoutAttributeTop
                                          multiplier:1
                                          constant:kMessageSeparatorHeight];
    topConstraint.priority = 900;

    NSLayoutConstraint * leftConstraint = [NSLayoutConstraint
                                           constraintWithItem:disclaimerView
                                           attribute:NSLayoutAttributeLeading
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:self.disclaimerView
                                           attribute:NSLayoutAttributeLeadingMargin
                                           multiplier:1
                                           constant:3];
    leftConstraint.priority = 900;

    NSLayoutConstraint * rightConstraint = [NSLayoutConstraint
                                            constraintWithItem:disclaimerView
                                            attribute:NSLayoutAttributeTrailing
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:self.disclaimerView
                                            attribute:NSLayoutAttributeTrailingMargin
                                            multiplier:1
                                            constant:-3];
    rightConstraint.priority = 900;

    NSLayoutConstraint * bottomConstraint = [NSLayoutConstraint
                                            constraintWithItem:disclaimerView
                                            attribute:NSLayoutAttributeBottom
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:self.disclaimerView
                                            attribute:NSLayoutAttributeBottom
                                            multiplier:1
                                            constant:0];
    bottomConstraint.priority = 900;

    [self.disclaimerView addConstraint: topConstraint];
    [self.disclaimerView addConstraint: leftConstraint];
    [self.disclaimerView addConstraint: rightConstraint];
    [self.disclaimerView addConstraint: bottomConstraint];

    [self layoutSubviews];
    [self layoutIfNeeded];
    [self layoutMargins];
    [self setNeedsDisplay];
    [self setNeedsLayout];
    [self setNeedsUpdateConstraints];
}

//-(void) addReviewMessage:(NSString *) message italic:(BOOL)italic prefix:(NSString *)prefix {
//    UILabel * messageLabel = [self createAndSizeMessageUILabel:message italic:italic prefix:prefix];
//    messageLabel.autoresizesSubviews = YES;
//    [self.disclaimerView insertSubview:messageLabel atIndex:0];
//
//    [self addConstraintsToMessage:messageLabel];
//
//    NSMutableArray * mutableDisclaimers = [self.disclaimerLabels mutableCopy];
//    [mutableDisclaimers addObject: messageLabel];
//    self.disclaimerLabels = [mutableDisclaimers copy];
//}

//-(UILabel *) createAndSizeMessageUILabel:(NSString *) message italic:(BOOL)italic prefix:(NSString *)prefix {
//    UIColor * textColor = [TTSDKBrokerCenterTableViewCell colorFromArray: self.data.textColor];
//
//    CGRect labelFrame = CGRectMake(self.disclaimerView.frame.origin.x, self.disclaimerView.frame.origin.y, self.disclaimerView.frame.size.width, 160.0f);
//    labelFrame.size.width = self.frame.size.width;
//    UILabel * label = [[UILabel alloc] initWithFrame: labelFrame];
//
//    NSString * prefixStr;
//    if ([prefix isEqualToString:@"asterisk"]) {
//        prefixStr = [NSString stringWithFormat:@"%C", 0x0000002A];
//    } else if ([prefix isEqualToString:@"dagger"]) {
//        prefixStr = [NSString stringWithFormat:@"%C", 0x00002020];
//    } else {
//        prefixStr = @"";
//    }
//
//    [label setText: [NSString stringWithFormat:@"%@%@", prefixStr, message]];
//    label.lineBreakMode = NSLineBreakByWordWrapping;
//    [label setTranslatesAutoresizingMaskIntoConstraints: NO];
//    [label setNumberOfLines: 0];
//    [label setTextColor: textColor];
//    [label setAdjustsFontSizeToFitWidth: NO];
//
//    if (italic) {
//        [label setFont: [UIFont italicSystemFontOfSize:10.0f]];
//    } else {
//        [label setFont: [UIFont systemFontOfSize:10.0f]];
//    }
//
//    label.frame = labelFrame;
//    [label sizeToFit];
//
//    NSLog(@"LABEL HEIGHT: %f", label.frame.size.height);
//
//    return label;
//}

/*
 NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"String with a link" attributes:nil];
 NSRange linkRange = NSMakeRange(14, 4);
 // for the word "link" in the string above  NSDictionary *linkAttributes = @{
 NSForegroundColorAttributeName : [UIColor colorWithRed:0.05 green:0.4 blue:0.65 alpha:1.0],                                   NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle) };
 [attributedString setAttributes:linkAttributes range:linkRange];
 // Assign attributedText to UILabel label.attributedText = attributedString;

 label.userInteractionEnabled = YES;
 [label addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnLabel:)]];

 // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
 NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeZero];
 NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedString];
 // Configure layoutManager and textStorage [layoutManager addTextContainer:textContainer];
 [textStorage addLayoutManager:layoutManager];
 // Configure textContainer textContainer.lineFragmentPadding = 0.0;
 textContainer.lineBreakMode = label.lineBreakMode;
 textContainer.maximumNumberOfLines = label.numberOfLines;
 
 - (void)handleTapOnLabel:(UITapGestureRecognizer *)tapGesture {
 CGPoint locationOfTouchInLabel = [tapGesture locationInView:tapGesture.view];
 CGSize labelSize = tapGesture.view.bounds.size;
 CGRect textBoundingBox = [self.layoutManager usedRectForTextContainer:self.textContainer];
 CGPoint textContainerOffset = CGPointMake((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,                                               (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
 CGPoint locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,                                                          locationOfTouchInLabel.y - textContainerOffset.y);
 NSInteger indexOfCharacter = [self.layoutManager characterIndexForPoint:locationOfTouchInTextContainer                                                             inTextContainer:self.textContainer                                    fractionOfDistanceBetweenInsertionPoints:nil];
 NSRange linkRange = NSMakeRange(14, 4);
 // it's better to save the range somewhere when it was originally used for marking link in attributed string     if (NSLocationInRange(indexOfCharacter, linkRange) {
 // Open an URL, or handle the tap on the link in any other way         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://stackoverflow.com/"]];
 }
 }
 
 */

//-(void) addConstraintsToMessage:(UILabel *) label {
//    NSLayoutConstraint * topConstraint = [NSLayoutConstraint
//                                          constraintWithItem:label
//                                          attribute:NSLayoutAttributeTop
//                                          relatedBy:NSLayoutRelationEqual
//                                          toItem:self.lastAttachedMessage
//                                          attribute:NSLayoutAttributeBottom
//                                          multiplier:1
//                                          constant:kMessageSeparatorHeight];
//    topConstraint.priority = 900;
//    
//    NSLayoutConstraint * leftConstraint = [NSLayoutConstraint
//                                           constraintWithItem:label
//                                           attribute:NSLayoutAttributeLeading
//                                           relatedBy:NSLayoutRelationEqual
//                                           toItem:self.disclaimerView
//                                           attribute:NSLayoutAttributeLeadingMargin
//                                           multiplier:1
//                                           constant:3];
//    leftConstraint.priority = 900;
//    
//    NSLayoutConstraint * rightConstraint = [NSLayoutConstraint
//                                            constraintWithItem:label
//                                            attribute:NSLayoutAttributeTrailing
//                                            relatedBy:NSLayoutRelationEqual
//                                            toItem:self.disclaimerView
//                                            attribute:NSLayoutAttributeTrailingMargin
//                                            multiplier:1
//                                            constant:-3];
//    rightConstraint.priority = 900;
//    
//    self.lastAttachedMessage = label;
//    
//    [self.disclaimerView addConstraint: topConstraint];
//    [self.disclaimerView addConstraint: leftConstraint];
//    [self.disclaimerView addConstraint: rightConstraint];
//}


#pragma Mark Populate data

-(void) populateSignupOffer {
    self.offerTitle.text = self.data.signupTitle;

    NSString * offerPostscript;

    if ([self.data.signupPostfix isEqualToString:@"asterisk"]) {
        offerPostscript = [NSString stringWithFormat:@"%C", 0x0000002A];
    } else if ([self.data.signupPostfix isEqualToString:@"dagger"]) {
        offerPostscript = [NSString stringWithFormat:@"%C", 0x00002020];
    } else {
        offerPostscript = @"";
    }

    self.offerDescription.text = [NSString stringWithFormat:@"%@%@", self.data.signupDescription, offerPostscript];
}

-(void) populateAccountMinimum {
    self.accountMinimum.text = [NSString stringWithFormat:@"Account Min: %@", self.data.accountMinimum];
}

-(void) populateOptionsOffer {
    NSString * offerPostscript;
    
    if ([self.data.optionsPostfix isEqualToString:@"asterisk"]) {
        offerPostscript = [NSString stringWithFormat:@"%C", 0x0000002A];
    } else if ([self.data.optionsPostfix isEqualToString:@"dagger"]) {
        offerPostscript = [NSString stringWithFormat:@"%C", 0x00002020];
    } else {
        offerPostscript = @"";
    }

    self.optionsOffer.text = [NSString stringWithFormat:@"%@%@", self.data.optionsOffer, offerPostscript];
}

-(void) populateStocksEtfsOffer {
    NSString * offerPostscript;
    
    if ([self.data.stocksEtfsPostfix isEqualToString:@"asterisk"]) {
        offerPostscript = [NSString stringWithFormat:@"%C", 0x0000002A];
    } else if ([self.data.stocksEtfsPostfix isEqualToString:@"dagger"]) {
        offerPostscript = [NSString stringWithFormat:@"%C", 0x00002020];
    } else {
        offerPostscript = @"";
    }

    self.stocksEtfsOffer.text = [NSString stringWithFormat:@"%@%@", self.data.stocksEtfsOffer, offerPostscript];
}

-(void) populateFeatures:(NSArray *)features {
    // This is all very gross, but not sure of any other way to accomplish this

    if (!features || !features.count) {
        self.featureSlot1.text = @"";
        self.featureSlot2.text = @"";
        self.featureSlot3.text = @"";
        self.featureSlot4.text = @"";
        self.featureSlot5.text = @"";
        self.featureSlot6.text = @"";
        self.featureSlot7.text = @"";
        self.featureSlot8.text = @"";

        return;
    }

    int count = (int)features.count;

    self.featureSlot1.text = [features objectAtIndex:0];

    if (count > 1) {
        self.featureSlot2.text = [features objectAtIndex:1];
    } else {
        self.featureSlot2.text = @"";
    }

    if (count > 2) {
        self.featureSlot3.text = [features objectAtIndex:2];
    } else {
        self.featureSlot3.text = @"";
    }
    
    if (count > 3) {
        self.featureSlot4.text = [features objectAtIndex:3];
    } else {
        self.featureSlot4.text = @"";
    }

    if (count > 4) {
        self.featureSlot5.text = [features objectAtIndex:4];
    } else {
        self.featureSlot5.text = @"";
    }

    if (count > 5) {
        self.featureSlot6.text = [features objectAtIndex:5];
    } else {
        self.featureSlot6.text = @"";
    }

    if (count > 6) {
        self.featureSlot7.text = [features objectAtIndex:6];
    } else {
        self.featureSlot7.text = @"";
    }

    if (count > 7) {
        self.featureSlot8.text = [features objectAtIndex:7];
    } else {
        self.featureSlot8.text = @"";
    }
}

-(void) populateDisclaimers {
    if (self.data.disclaimers && self.data.disclaimers.count) {
//        self.disclaimerHeightConstraint.constant = 160.0f;

//        for (NSDictionary * disclaimerData in self.data.disclaimers) {
//            UILabel * disclaimerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 40.0f)];
//            disclaimerLabel.lineBreakMode = NSLineBreakByWordWrapping;
//            disclaimerLabel.numberOfLines = 0; // allows multiple lines
//            disclaimerLabel.text = [disclaimerData valueForKey:@"content"];
//            [self.disclaimerView addSubview: disclaimerLabel];

//            [self addReviewMessage:[disclaimerData valueForKey:@"content"] italic:[[disclaimerData valueForKey:@"italic"] boolValue] prefix:[disclaimerData valueForKey:@"prefix"]];
//        }

    } else {
        self.disclaimerHeightConstraint.constant = 0.0f;
    }
}


#pragma Mark Events

- (IBAction)toggleExpandedPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didToggleExpandedView:atIndexPath:)]) {
        [self.delegate didToggleExpandedView:!self.expandedViewToggled atIndexPath:self.indexPath];
    }
}

- (IBAction)promptPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didSelectLink:withTitle:)] && ![self.data.promptUrl isEqualToString:@""]) {
        [self.delegate didSelectLink: self.data.promptUrl withTitle: [self.ticket getBrokerDisplayString: self.data.broker]];
    }
}

- (IBAction)disclaimerButtonPressed:(id)sender {
    self.disclaimerToggled = !self.disclaimerToggled;
    
    if ([self.delegate respondsToSelector:@selector(didSelectDisclaimer:withHeight:atIndexPath:)]) {
        [self.delegate didSelectDisclaimer:self.disclaimerToggled withHeight:self.disclaimerLabelsTotalHeight atIndexPath:self.indexPath];

        if (self.disclaimerToggled) {
            [self.disclaimerButton setTitle:@"CLOSE" forState:UIControlStateNormal];
        } else {
            [self.disclaimerButton setTitle:@"DISCLAIMER" forState:UIControlStateNormal];
        }
    }
}


@end
