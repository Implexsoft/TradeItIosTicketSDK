//
//  TTSDKPortfolioHoldingTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/6/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioHoldingTableViewCell.h"
#import "TTSDKPosition.h"
#import "TTSDKUtils.h"
#import "TTSDKTradeItTicket.h"

@interface TTSDKPortfolioHoldingTableViewCell () {
    TTSDKUtils * utils;
    TTSDKPosition * currentPosition;
    TTSDKTradeItTicket * globalTicket;
}

@property (weak, nonatomic) IBOutlet UIButton *sellButton;
@property (weak, nonatomic) IBOutlet UIButton *buyButton;
@property (weak, nonatomic) IBOutlet UIView *secondaryView;
@property (weak, nonatomic) IBOutlet UIView *primaryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *primaryLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *primaryRightConstraint;
@property (nonatomic, assign) CGFloat startingRightLayoutConstraint;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, assign) CGPoint panStartPoint;

@property (weak, nonatomic) IBOutlet UILabel *symbolLabel;
@property (weak, nonatomic) IBOutlet UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UILabel *changeLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UILabel *bidLabel;
@property (weak, nonatomic) IBOutlet UILabel *askLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalReturnValueLabel;

@end

@implementation TTSDKPortfolioHoldingTableViewCell



#pragma mark - Constants

static CGFloat const kBounceValue = 20.0f;



#pragma mark - Initialization

- (void) awakeFromNib {
    [super awakeFromNib];

    utils = [TTSDKUtils sharedUtils];
    globalTicket = [TTSDKTradeItTicket globalTicket];

    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCell:)];
    self.panRecognizer.delegate = self;
    [self.primaryView addGestureRecognizer:self.panRecognizer];

    UITapGestureRecognizer * buyTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buySelected:)];
    [self.buyButton addGestureRecognizer: buyTap];

    UITapGestureRecognizer * sellTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sellSelected:)];
    [self.sellButton addGestureRecognizer: sellTap];
}

-(IBAction) sellSelected:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didSelectSell:)]) {
        [self.delegate didSelectSell: currentPosition];
    }
}

-(IBAction) buySelected:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didSelectBuy:)]) {
        [self.delegate didSelectBuy: currentPosition];
    }
}

#pragma mark - Configuration

-(void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(void) hideSeparator {
    self.separatorView.hidden = YES;
}

-(void) showSeparator {
    self.separatorView.hidden = NO;
}

-(void) configureCellWithPosition:(TTSDKPosition *)position {
    currentPosition = position;

    NSString * cost = [position.costbasis stringValue] ?: @"N/A";

    NSString * quantityPostfix = @"";
    if (position.quantity < 0) {
        quantityPostfix = @" x%@", [position.quantity stringValue];
    }

    NSString * quantityStr = [position.quantity stringValue];
    if ([quantityStr rangeOfString:@"."].location != NSNotFound) {
        quantityStr = [NSString stringWithFormat:@"%.02f", fabs([position.quantity floatValue])];
    } else {
        quantityStr = [NSString stringWithFormat:@"%i", abs([position.quantity intValue])];
    }

    self.symbolLabel.text = [NSString stringWithFormat:@"%@ (%@%@)", position.symbol, quantityStr, quantityPostfix];
    self.costLabel.text = [cost isEqualToString:@"0"] ? @"N/A" : cost;

    // Bid and Ask
    NSString * bid;
    if (position.quote.bidPrice) {
        bid = [NSString stringWithFormat:@"%.02f", [position.quote.bidPrice floatValue]];
    } else {
        bid = @"N/A";
    }
    NSString * ask;
    if (position.quote.askPrice) {
        ask = [NSString stringWithFormat:@"%.02f", [position.quote.askPrice floatValue]];
    } else {
        ask = @"N/A";
    }
    self.bidLabel.text = bid;
    self.askLabel.text = ask;

    // Change
    NSString * dailyChange;
    UIColor * changeColor;
    NSString * changePrefix;
    NSString * changeStr;
    if (position.todayGainLossDollar) {
        if ([position.todayGainLossDollar floatValue] > 0) {
            changeColor = utils.gainColor;
            changePrefix = @"+";
        } else if ([position.todayGainLossDollar floatValue] == 0) {
            changeColor = [UIColor lightGrayColor];
            changeStr = @"N/A";
        } else {
            changeColor = utils.lossColor;
            changePrefix = @"";
        }

        if (!changeStr) {
            changeStr = [NSString stringWithFormat:@"%@%.02f(%.02f%@)", changePrefix, [position.todayGainLossDollar floatValue], [position.todayGainLossPercentage floatValue], @"%"];
        }

        dailyChange = changeStr;

    } else {
        changeColor = [UIColor lightGrayColor];
        dailyChange = @"N/A";
    }
    self.changeLabel.text = dailyChange;
    self.changeLabel.textColor = changeColor;

    // Total Value
    NSString * totalValue;
    if (position.totalValue) {
        totalValue = [NSString stringWithFormat:@"$%.02f", [position.totalValue floatValue]];
    } else {
        totalValue = @"N/A";
    }
    self.totalValueLabel.text = totalValue;

    // Total Return
    NSString * totalReturn;
    if (position.todayGainLossDollar) {
        totalReturn = [NSString stringWithFormat:@"%@%.02f", changePrefix ?: @"", [position.todayGainLossDollar floatValue]];
    } else {
        totalReturn = @"N/A";
    }
    self.totalReturnValueLabel.text = totalReturn;
    self.totalReturnValueLabel.textColor = changeColor;

    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

-(CGFloat) secondaryViewWidth {
    return self.secondaryView.frame.size.width;
}



#pragma mark - Custom UI

-(void) panCell:(UIPanGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            self.panStartPoint = [recognizer translationInView:self.primaryView];
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint currentPoint = [recognizer translationInView: self.primaryView];
            CGFloat deltaX = currentPoint.x - self.panStartPoint.x;
            BOOL panningLeft = NO;
            if (currentPoint.x < self.panStartPoint.x) {
                panningLeft = YES;
            }

            if (self.startingRightLayoutConstraint == 0) {
                if (!panningLeft) {
                    CGFloat constant = MAX(-deltaX, 0);
                    if (constant == 0) {
                        [self resetConstraintsToZero:YES notifyDelegateDidClose:NO];
                    } else {
                        self.primaryRightConstraint.constant = constant;
                    }
                } else {
                    CGFloat constant = MIN(-deltaX, [self secondaryViewWidth]);
                    if (constant == [self secondaryViewWidth]) {
                        [self setConstraintsToShowOptions:YES notifyDelegateDidOpen:NO];
                    } else {
                        self.primaryRightConstraint.constant = constant;
                    }
                }
            } else {
                CGFloat adjustment = self.startingRightLayoutConstraint - deltaX;
                if (!panningLeft) {
                    CGFloat constant = MAX(adjustment, 0);
                    if (constant == 0) {
                        [self resetConstraintsToZero:YES notifyDelegateDidClose:NO];
                    } else {
                        self.primaryRightConstraint.constant = constant;
                    }
                } else {
                    CGFloat constant = MIN(adjustment, [self secondaryViewWidth]);
                    if (constant == [self secondaryViewWidth]) {
                        [self setConstraintsToShowOptions:YES notifyDelegateDidOpen:NO];
                    } else {
                        self.primaryRightConstraint.constant = constant;
                    }
                }
            }

            self.primaryLeftConstraint.constant = -self.primaryRightConstraint.constant;
        }
            break;
        case UIGestureRecognizerStateEnded:
            if (self.startingRightLayoutConstraint == 0) {
                CGFloat quarterWay = [self secondaryViewWidth] / 4;
                if (self.primaryRightConstraint.constant >= quarterWay) {
                    [self setConstraintsToShowOptions:YES notifyDelegateDidOpen:YES];
                } else {
                    [self resetConstraintsToZero:YES notifyDelegateDidClose:YES];
                }
            } else {
                CGFloat threeQuarters = [self secondaryViewWidth] - ([self secondaryViewWidth] / 4);
                if (self.primaryRightConstraint.constant >= threeQuarters) {
                    [self setConstraintsToShowOptions:YES notifyDelegateDidOpen:YES];
                } else {
                    [self resetConstraintsToZero:YES notifyDelegateDidClose:YES];
                }
            }
            break;
        case UIGestureRecognizerStateCancelled:
            if (self.startingRightLayoutConstraint == 0) {
                [self resetConstraintsToZero:YES notifyDelegateDidClose:YES];
            } else {
                [self setConstraintsToShowOptions:YES notifyDelegateDidOpen:YES];
            }
            break;
        default:
            break;
    }
}

-(void) updateConstraintsIfNeeded:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    float duration = 0;
    if (animated) {
        duration = 0.1;
    }

    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self layoutIfNeeded];
    } completion:completion];
}

-(void) resetConstraintsToZero:(BOOL) animated notifyDelegateDidClose:(BOOL) endEditing {
    if (self.startingRightLayoutConstraint == 0 && self.primaryRightConstraint.constant == 0) {
        return;
    }

    self.primaryRightConstraint.constant = -kBounceValue;
    self.primaryLeftConstraint.constant = kBounceValue;

    [self updateConstraintsIfNeeded:animated completion:^(BOOL finished) {
        self.primaryRightConstraint.constant = 0;
        self.primaryLeftConstraint.constant = 0;

        [self updateConstraintsIfNeeded:animated completion:^(BOOL finished) {
            self.startingRightLayoutConstraint = self.primaryRightConstraint.constant;
        }];
    }];
}

-(void) setConstraintsToShowOptions:(BOOL) animated notifyDelegateDidOpen:(BOOL) notifyDelegate {
    if (self.startingRightLayoutConstraint == [self secondaryViewWidth] && self.primaryRightConstraint.constant == [self secondaryViewWidth]) {
        return;
    }

    self.primaryLeftConstraint.constant = -[self secondaryViewWidth] - kBounceValue;
    self.primaryRightConstraint.constant = [self secondaryViewWidth] + kBounceValue;

    [self updateConstraintsIfNeeded:animated completion:^(BOOL finished) {
        self.primaryLeftConstraint.constant = -[self secondaryViewWidth];
        self.primaryRightConstraint.constant = [self secondaryViewWidth];

        [self updateConstraintsIfNeeded:animated completion:^(BOOL finished) {
            self.startingRightLayoutConstraint = self.primaryRightConstraint.constant;
        }];
    }];
}



@end
