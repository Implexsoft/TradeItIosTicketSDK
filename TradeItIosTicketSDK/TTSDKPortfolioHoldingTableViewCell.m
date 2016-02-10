//
//  TTSDKPortfolioHoldingTableViewCell.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 1/6/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKPortfolioHoldingTableViewCell.h"

@interface TTSDKPortfolioHoldingTableViewCell () {
//    TradeItPosition * position;
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
@property (weak, nonatomic) IBOutlet UILabel *dailyReturnValue;
@property (weak, nonatomic) IBOutlet UILabel *totalReturnValueLabel;

@end

@implementation TTSDKPortfolioHoldingTableViewCell



#pragma mark - Constants

static CGFloat const kBounceValue = 20.0f;



#pragma mark - Initialization

- (void) awakeFromNib {
    [super awakeFromNib];

    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCell:)];
    self.panRecognizer.delegate = self;
    [self.primaryView addGestureRecognizer:self.panRecognizer];
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

-(void) configureCellWithPosition:(TradeItPosition *)position {
    NSString * symbol = position.symbol;
    NSString * cost = [position.costbasis stringValue];
    NSString * change = [position.todayGainLossDollar stringValue];
    
    NSString * bid = [position.lastPrice stringValue];
    NSString * ask = [position.lastPrice stringValue];
    NSString * totalValue = [position.totalGainLossDollar stringValue];
    NSString * dailyReturn = [position.todayGainLossDollar stringValue];
    NSString * totalReturn = [position.totalGainLossDollar stringValue];

    self.symbolLabel.text = symbol;
    self.costLabel.text = cost;
    self.changeLabel.text = change;
    
    self.bidLabel.text = bid;
    self.askLabel.text = ask;
    self.totalValueLabel.text = totalValue;
    self.dailyReturnValue.text = dailyReturn;
    self.totalReturnValueLabel.text = totalReturn;
    
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
