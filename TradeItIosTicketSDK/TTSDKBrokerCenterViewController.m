//
//  TTSDKBrokerCenterViewController.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 5/9/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKBrokerCenterViewController.h"
#import "TTSDKBrokerCenterTableViewCell.h"

@interface TTSDKBrokerCenterViewController ()

@property NSLayoutManager * layoutManager;
@property NSArray * brokerCenterData;
@property NSArray * brokerCenterImages;
@property NSArray * disclaimers;
@property NSMutableArray * links;
@property NSMutableArray * brokerCenterImagesLoadingQueue;
@property NSIndexPath * disclaimerIndexPath;
@property NSInteger selectedIndex;
@property CGFloat currentDisclaimerHeight;
@property BOOL disclaimerOpen;
@property UIColor * firstItemBackgroundColor;
@property UIColor * lastItemBackgroundColor;

@end

@implementation TTSDKBrokerCenterViewController

static CGFloat kDefaultHeight = 175.0f;
static CGFloat kExpandedHeight = 330.0f;


-(void) viewDidLoad {
    [super viewDidLoad];

    self.links = [[NSMutableArray alloc] init];

    self.disclaimerOpen = NO;

    self.tableView.allowsSelection = NO;
    self.tableView.allowsMultipleSelection = NO;
    self.tableView.allowsSelectionDuringEditing = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;

    if (self.isModal) {
        UIBarButtonItem * closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closePressed:)];
        self.navigationItem.rightBarButtonItem = closeButton;
    }

    self.brokerCenterImages = [[NSArray alloc] init];

    if (self.ticket.adService.brokerCenterBrokers) {
        [self populateBrokerDataByActiveFilter];
    }

    // make sure to update this once real data is being used
    UIColor * firstItemBackgroundColor = [TTSDKBrokerCenterTableViewCell colorFromArray:[[self.brokerCenterData firstObject] valueForKey:@"backgroundColor"]];
    UIColor * lastItemBackgroundColor = [TTSDKBrokerCenterTableViewCell colorFromArray:[[self.brokerCenterData lastObject] valueForKey:@"backgroundColor"]];
    self.firstItemBackgroundColor = firstItemBackgroundColor;
    self.lastItemBackgroundColor = lastItemBackgroundColor;

    self.brokerCenterImagesLoadingQueue = [[NSMutableArray alloc] init];
    for (NSDictionary * brokerCenterData in self.brokerCenterData) {
        NSNumber * ind = [[NSNumber alloc] initWithInteger:[self.brokerCenterData indexOfObject:brokerCenterData]];
        NSDictionary * queueItem = @{@"broker":[brokerCenterData valueForKey:@"broker"], @"logo": [brokerCenterData valueForKey:@"logo"], @"index": ind};
        [self.brokerCenterImagesLoadingQueue addObject: queueItem];
    }

    self.selectedIndex = -1;

    [self setDisclaimerLabelsAndSizes];
}

-(void) populateBrokerDataByActiveFilter {
    NSMutableArray * brokerList = [[NSMutableArray alloc] init];

    for (TradeItBrokerCenterBroker *broker in self.ticket.adService.brokerCenterBrokers) {
        if (broker.active) {
            [brokerList addObject: broker];
        }
    }

    self.brokerCenterData = [brokerList copy];
}

-(void) setDisclaimerLabelsAndSizes {
    NSMutableArray * disclaimersArray = [[NSMutableArray alloc] init];

    for (TradeItBrokerCenterBroker * broker in self.brokerCenterData) {
        NSArray * disclaimers = broker.disclaimers;

        float totalLabelsHeight = 0.0f;

        UIView * containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 100.0f)];
        containerView.backgroundColor = [UIColor clearColor];

        UILabel * keyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 12.0f)];
        keyLabel.text = @"";
        [keyLabel sizeToFit];
        [containerView insertSubview:keyLabel atIndex:0];

        NSLayoutConstraint * topKeyConstraint = [NSLayoutConstraint
                                              constraintWithItem:keyLabel
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                              toItem:containerView
                                              attribute:NSLayoutAttributeTop
                                              multiplier:1
                                              constant:0];
        topKeyConstraint.priority = 900;

        NSLayoutConstraint * leftKeyConstraint = [NSLayoutConstraint
                                               constraintWithItem:keyLabel
                                               attribute:NSLayoutAttributeLeading
                                               relatedBy:NSLayoutRelationEqual
                                               toItem:containerView
                                               attribute:NSLayoutAttributeLeadingMargin
                                               multiplier:1
                                               constant:3];
        leftKeyConstraint.priority = 900;

        NSLayoutConstraint * rightKeyConstraint = [NSLayoutConstraint
                                                constraintWithItem:keyLabel
                                                attribute:NSLayoutAttributeTrailing
                                                relatedBy:NSLayoutRelationEqual
                                                toItem:containerView
                                                attribute:NSLayoutAttributeTrailingMargin
                                                multiplier:1
                                                constant:-3];
        rightKeyConstraint.priority = 900;

        [containerView addConstraint:topKeyConstraint];
        [containerView addConstraint:leftKeyConstraint];
        [containerView addConstraint:rightKeyConstraint];

        UILabel * lastAttachedLabel = keyLabel;

        for (NSDictionary * disclaimer in disclaimers) {
            BOOL isItalic = [[disclaimer valueForKey:@"italic"] boolValue];
            UIColor * textColor = [TTSDKBrokerCenterTableViewCell colorFromArray: broker.textColor];
            NSString * prefixStr;
            NSString * prefix = [disclaimer valueForKey:@"prefix"];

            if ([prefix isEqualToString:@"asterisk"]) {
                prefixStr = [NSString stringWithFormat:@"%C", 0x0000002A];
            } else if ([prefix isEqualToString:@"dagger"]) {
                prefixStr = [NSString stringWithFormat:@"%C", 0x00002020];
            } else {
                prefixStr = @"";
            }

            UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 100.0f)];

            NSString * message = [NSString stringWithFormat:@"%@%@", prefixStr, [disclaimer valueForKey:@"content"]];

            NSArray * componentByBeginningString = [message componentsSeparatedByString:@"{{"];

            NSMutableAttributedString * attributedStringByComponent = [[NSMutableAttributedString alloc] init];

            if (componentByBeginningString.count > 1) {
                NSMutableArray * mutableComponentByEndingString = [[NSMutableArray alloc ] init];
                NSDictionary *linkAttributes = @{
                                                 NSFontAttributeName: [UIFont boldSystemFontOfSize:label.font.pointSize],
                                                 NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)
                                                 };

                for (NSString *component in componentByBeginningString) {

                    NSArray * endComponent = [component componentsSeparatedByString:@"}}"];
                    [mutableComponentByEndingString addObject:endComponent];
                }

                NSArray * componentByEndingString = [mutableComponentByEndingString copy];

                NSMutableArray * hrefsHolder = [[NSMutableArray alloc] init];
                NSArray * hrefs = (NSArray *)[disclaimer valueForKey:@"hrefs"];

                int hrefCounter = 0;

                for (NSArray * endingComponent in componentByEndingString) {

                    if (endingComponent.count == 2) {

                        NSAttributedString * attributedEndingComponent = [[NSAttributedString alloc] initWithString:(NSString *)[endingComponent firstObject] attributes:linkAttributes];

                        [hrefsHolder addObject:@{@"href": (NSString *)[hrefs objectAtIndex: hrefCounter], @"title": [attributedEndingComponent string]}];
                        hrefCounter++;

                        [attributedStringByComponent appendAttributedString: attributedEndingComponent];

                        NSAttributedString * attributedEndingHangingComponent = [[NSAttributedString alloc] initWithString:(NSString *)[endingComponent lastObject]];

                        [attributedStringByComponent appendAttributedString: attributedEndingHangingComponent];
                    } else {

                        [attributedStringByComponent appendAttributedString:[[NSAttributedString alloc] initWithString:(NSString *)[endingComponent firstObject]]];
                    }
                }

                [self.links addObject:@{@"broker": broker.broker, @"hrefs": [hrefsHolder copy]}];

                label.userInteractionEnabled = YES;
                label.attributedText = [attributedStringByComponent copy];

                UITapGestureRecognizer * linkTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(linkPressed:)];
                [label addGestureRecognizer: linkTap];
            } else {
                label.text = message;
            }

            label.lineBreakMode = NSLineBreakByWordWrapping;
            label.autoresizesSubviews = YES;
            label.adjustsFontSizeToFitWidth = NO;
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.numberOfLines = 0;
            label.textColor = textColor;

            if (isItalic) {
                label.font = [UIFont italicSystemFontOfSize:10.0f];
            } else {
                label.font = [UIFont systemFontOfSize:10.0f];
            }

            [label sizeToFit];

            totalLabelsHeight += (label.frame.size.height + 10.0f);
            containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y, containerView.frame.size.width, totalLabelsHeight);

            [containerView insertSubview:label belowSubview:lastAttachedLabel];

            NSLayoutConstraint * topConstraint = [NSLayoutConstraint
                                                  constraintWithItem:label
                                                  attribute:NSLayoutAttributeTop
                                                  relatedBy:NSLayoutRelationEqual
                                                  toItem:lastAttachedLabel
                                                  attribute:NSLayoutAttributeBottom
                                                  multiplier:1
                                                  constant:10.0f];
            topConstraint.priority = 900;
            
            NSLayoutConstraint * leftConstraint = [NSLayoutConstraint
                                                   constraintWithItem:label
                                                   attribute:NSLayoutAttributeLeading
                                                   relatedBy:NSLayoutRelationEqual
                                                   toItem:containerView
                                                   attribute:NSLayoutAttributeLeadingMargin
                                                   multiplier:1
                                                   constant:3];
            leftConstraint.priority = 900;
            
            NSLayoutConstraint * rightConstraint = [NSLayoutConstraint
                                                    constraintWithItem:label
                                                    attribute:NSLayoutAttributeTrailing
                                                    relatedBy:NSLayoutRelationEqual
                                                    toItem:containerView
                                                    attribute:NSLayoutAttributeTrailingMargin
                                                    multiplier:1
                                                    constant:-3];
            rightConstraint.priority = 900;

            [containerView addConstraint: topConstraint];
            [containerView addConstraint: leftConstraint];
            [containerView addConstraint: rightConstraint];

            lastAttachedLabel = label;
        }

        [disclaimersArray addObject:@{@"view": containerView, @"totalHeight": [NSNumber numberWithFloat: totalLabelsHeight + 30.0f]}];
    }

    self.disclaimers = [disclaimersArray copy];
}

- (NSArray *)rangesOfString:(NSString *)searchString inString:(NSString *)str {
    NSMutableArray *results = [NSMutableArray array];
    NSRange searchRange = NSMakeRange(0, [str length]);
    NSRange range;
    while ((range = [str rangeOfString:searchString options:0 range:searchRange]).location != NSNotFound) {
        [results addObject:[NSValue valueWithRange:range]];
        searchRange = NSMakeRange(NSMaxRange(range), [str length] - NSMaxRange(range));
    }
    return results;
}

-(IBAction) closePressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction) linkPressed:(id)sender {
    TradeItBrokerCenterBroker * selectedBroker = [self.brokerCenterData objectAtIndex: self.selectedIndex];

    NSArray * selectedLinksList;

    for (NSDictionary * link in self.links) {
        NSString * broker = [link valueForKey:@"broker"];

        if ([selectedBroker.broker isEqualToString:broker]) {
            selectedLinksList = (NSArray *)[link valueForKey:@"hrefs"];
        }
    }

    if (!selectedLinksList || !selectedLinksList.count) {
        return;
    }

    NSDictionary * firstLinkItem = (NSDictionary *)[selectedLinksList firstObject];

    if (selectedLinksList.count == 1) {
        [self showWebViewWithURL: [firstLinkItem valueForKey:@"href"] andTitle:[firstLinkItem valueForKey:@"title"]];
    } else {

        NSMutableArray * optionsArray = [[NSMutableArray alloc] init];
        for (NSDictionary *linkItem in selectedLinksList) {
            [optionsArray addObject:@[[linkItem valueForKey:@"title"], [linkItem valueForKey:@"href"]]];
        }

        [self showPicker:@"Select a link" withSelection:[firstLinkItem valueForKey:@"href"] andOptions:[optionsArray copy] onSelection:^(void){
            dispatch_async(dispatch_get_main_queue(), ^{
            });
        }];
    }
}

-(void) didToggleExpandedView:(BOOL)toggled atIndexPath:(NSIndexPath *)indexPath {
    // reset the background color
    TradeItBrokerCenterBroker * data = (TradeItBrokerCenterBroker *)[self.brokerCenterData objectAtIndex:indexPath.row];
    UIColor * bgColor = [TTSDKBrokerCenterTableViewCell colorFromArray:[data valueForKey:@"backgroundColor"]];
    self.tableView.backgroundColor = bgColor;

    // shut disclaimer every time you toggle
    self.disclaimerOpen = NO;

    if (self.selectedIndex == -1) { // user taps row with none currently expanded
        self.selectedIndex = indexPath.row;

        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
    } else if (self.selectedIndex == indexPath.row) { // user taps the currenty expanded row
        self.selectedIndex = -1; // reset index

        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
    } else { // user must have selected a different row
        // get the previous selection path
        NSIndexPath * prevPath = [NSIndexPath indexPathForRow: self.selectedIndex inSection: 0];
        
        // reset the disclaimer
        TTSDKBrokerCenterTableViewCell * cell = [self.tableView cellForRowAtIndexPath:prevPath];
        cell.disclaimerToggled = NO;
        
        self.selectedIndex = indexPath.row;

        [CATransaction begin];
        [self.tableView beginUpdates];

        [CATransaction setCompletionBlock: ^{
            [self.tableView reloadData];
        }];
        
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:prevPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        [CATransaction commit];
    }
    
    [self.tableView layoutIfNeeded];
}

-(void) didSelectLink:(NSString *)link withTitle:(NSString *)title {
    [self showWebViewWithURL:link andTitle:title];
}

-(void) didSelectDisclaimer:(BOOL)selected withHeight:(CGFloat)height atIndexPath:(NSIndexPath *)indexPath {
    self.disclaimerOpen = selected;
    self.currentDisclaimerHeight = height;
    self.disclaimerIndexPath = indexPath;

    [self.tableView reloadData];
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.brokerCenterData.count;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedIndex == indexPath.row) {

        if (self.disclaimerOpen && self.disclaimerIndexPath.row == indexPath.row) {
            NSDictionary * disclaimer = [self.disclaimers objectAtIndex:indexPath.row];
            float disclaimerHeight = [[disclaimer valueForKey:@"totalHeight"] floatValue];
            return kExpandedHeight + (disclaimerHeight ? disclaimerHeight : 0.0f);
        } else {
            return kExpandedHeight;
        }
    } else {
        return kDefaultHeight;
    }
}

-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y > 0) {
        scrollView.backgroundColor = self.lastItemBackgroundColor;
    } else {
        scrollView.backgroundColor = self.firstItemBackgroundColor;
    }
}

-(void) promptButtonPressed:(id)sender {
    [self showWebViewWithURL:@"https://www.trade.it/terms" andTitle:@"Terms"];
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * cellIdentifier;
    NSString * nibIdentifier;
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"]];

    cellIdentifier = @"BrokerCenterIdentifier";
    nibIdentifier = @"TTSDKBrokerCenterCell";
    TTSDKBrokerCenterTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];

    [tableView registerNib:[UINib nibWithNibName: nibIdentifier bundle:resourceBundle] forCellReuseIdentifier:cellIdentifier];
    cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (self.disclaimerOpen && self.disclaimerIndexPath.row == indexPath.row) {
        cell.disclaimerToggled = YES;

        NSDictionary * disclaimer = [self.disclaimers objectAtIndex:indexPath.row];

        float totalHeight = [[disclaimer valueForKey:@"totalHeight"] floatValue];
        cell.disclaimerLabelsTotalHeight = totalHeight;

        UIView * disclaimerView = (UIView *)[disclaimer valueForKey:@"view"];

        [cell configureDisclaimers: disclaimerView];
    } else {
        cell.disclaimerToggled = NO;
    }

    TradeItBrokerCenterBroker * brokerCenterItem = [self.brokerCenterData objectAtIndex: indexPath.row];
    [cell configureWithBroker: brokerCenterItem];
    UIImage * img = [self.ticket.adService logoImageByBoker: [brokerCenterItem valueForKey:@"broker"]];

    [cell addImage:img];

    BOOL selected = self.selectedIndex == indexPath.row;
    [cell configureSelectedState: selected];

    cell.indexPath = indexPath;
    cell.delegate = self;

    return cell;
}


@end
