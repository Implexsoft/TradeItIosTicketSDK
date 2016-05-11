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

@property NSArray * brokerCenterData;
@property NSArray * brokerCenterImages;
@property NSMutableArray * brokerCenterImagesLoadingQueue; // loading by recursion
@property NSInteger selectedIndex;

@property UIColor * firstItemBackgroundColor;
@property UIColor * lastItemBackgroundColor;

@property BOOL disclaimerOpen;

@end

@implementation TTSDKBrokerCenterViewController

static CGFloat kDefaultHeight = 175.0f;
static CGFloat kExpandedHeight = 330.0f;


-(void) viewDidLoad {
    [super viewDidLoad];

    self.disclaimerOpen = NO;

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

-(IBAction) closePressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) didSelectLink:(NSString *)link withTitle:(NSString *)title {
    [self showWebViewWithURL:link andTitle:title];
}

-(void) didSelectDisclaimer:(BOOL)selected {
    self.disclaimerOpen = selected;

    [self.tableView reloadData];
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.brokerCenterData.count;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedIndex == indexPath.row) {
        if (self.disclaimerOpen) {
            return kExpandedHeight + 160.0f;
        } else {
            return kExpandedHeight;
        }
    } else {
        return kDefaultHeight;
    }
}

-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y > 50) {
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

    if (cell == nil) {
        [tableView registerNib:[UINib nibWithNibName: nibIdentifier bundle:resourceBundle] forCellReuseIdentifier:cellIdentifier];

        cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    TradeItBrokerCenterBroker * brokerCenterItem = [self.brokerCenterData objectAtIndex: indexPath.row];
    [cell configureWithBroker: brokerCenterItem];
    UIImage * img = [self.ticket.adService logoImageByBoker: [brokerCenterItem valueForKey:@"broker"]];

    [cell addImage:img];

    BOOL selected = self.selectedIndex == indexPath.row;
    [cell configureSelectedState: selected];

    cell.delegate = self;

    return cell;
}

-(NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    TradeItBrokerCenterBroker * data = (TradeItBrokerCenterBroker *)[self.brokerCenterData objectAtIndex:indexPath.row];
    UIColor * bgColor = [TTSDKBrokerCenterTableViewCell colorFromArray:[data valueForKey:@"backgroundColor"]];

    self.tableView.backgroundColor = bgColor;

    return indexPath;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedIndex == -1) { // user taps row with none currently expanded
        self.selectedIndex = indexPath.row;

        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];

    } else if (self.selectedIndex == indexPath.row) { // user taps the currenty expanded row
        self.selectedIndex = -1; // reset index

        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];

    } else { // user must have selected a different row
         // shut disclaimer
        self.disclaimerOpen = NO;

        // get the previous selection path
        NSIndexPath * prevPath = [NSIndexPath indexPathForRow: self.selectedIndex inSection: 0];

        // reset the disclaimer
        TTSDKBrokerCenterTableViewCell * cell = [self.tableView cellForRowAtIndexPath:prevPath];
        cell.disclaimerToggled = NO;

        self.selectedIndex = indexPath.row;

        [CATransaction begin];
        [tableView beginUpdates];

        [CATransaction setCompletionBlock: ^{
            [tableView reloadData];
        }];

        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:prevPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
        [CATransaction commit];
    }

    [tableView layoutIfNeeded];
}


@end
