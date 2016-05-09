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

@end

@implementation TTSDKBrokerCenterViewController

static CGFloat kDefaultHeight = 175.0f;
static CGFloat kExpandedHeight = 330.0f;

-(void) viewDidLoad {
    [super viewDidLoad];

    self.brokerCenterImages = [[NSArray alloc] init];

    // used in place of real data
    self.brokerCenterData = @[
                              @{
                                  @"broker":@"fidelity",
                                  @"logo":@"",
                                  @"logoActive": @"1",
                                  @"offerTitle":@"Free Trades for 60 days & Up to $600",
                                  @"offerDescription": @"Open an Account",
                                  @"accountMinimum": @"$2,500",
                                  @"optionsOffer": @"$7.95 + $.75/contract",
                                  @"stocksEtfsOffer": @"$7.95 Online Trades",
                                  @"backgroundColor": [UIColor colorWithRed:80.0f/255.0f green:185.0f/255.0f blue:72.0f/255.0f alpha:1.0f],
                                  @"textColor": [UIColor whiteColor],
                                  @"buttonBackgroundColor": [UIColor colorWithRed:255.0f/255.0f green:155.0f/255.0f blue:64.0f/255.0f alpha:1.0f]
                                  },
                              @{
                                  @"broker":@"etrade",
                                  @"logo":@"",
                                  @"logoActive": @"1",
                                  @"offerTitle":@"Free Trades for 60 days & Up to $600",
                                  @"offerDescription": @"Open an Account",
                                  @"accountMinimum": @"$10,000",
                                  @"optionsOffer": @"$9.99 + $.75/contract",
                                  @"stocksEtfsOffer": @"$9.99 Online Trades",
                                  @"backgroundColor": [UIColor colorWithRed:23.0f/255.0f green:34.0f/255.0f blue:61.0f/255.0f alpha:1.0f],
                                  @"textColor": [UIColor whiteColor],
                                  @"buttonBackgroundColor": [UIColor colorWithRed:170.0f/255.0f green:123.0f/255.0f blue:228.0f/255.0f alpha:1.0f]
                                  },
                              @{
                                  @"broker":@"scottrade",
                                  @"logo":@"",
                                  @"logoActive": @"1",
                                  @"offerTitle":@"50 Free Trades",
                                  @"offerDescription": @"Open an Account",
                                  @"accountMinimum": @"$2,500",
                                  @"optionsOffer": @"$7 + $1.25/contract",
                                  @"stocksEtfsOffer": @"$7 Online Trades",
                                  @"backgroundColor": [UIColor colorWithRed:66.0f/255.0f green:20.0f/255.0f blue:106.0f/255.0f alpha:1.0f],
                                  @"textColor": [UIColor whiteColor],
                                  @"buttonBackgroundColor": [UIColor whiteColor]
                                  },
                              @{
                                  @"broker":@"optionshouse",
                                  @"logo":@"",
                                  @"logoActive": @"1",
                                  @"offerTitle":@"Free Trades for 60 days & Up to $600",
                                  @"offerDescription": @"Open an Account",
                                  @"accountMinimum": @"$2,500",
                                  @"optionsOffer": @"$4.95 + $.50/contract",
                                  @"stocksEtfsOffer": @"$4.95 Online Trades",
                                  @"backgroundColor": [UIColor colorWithRed:224.0f/255.0f green:255.0f/255.0f blue:176.0f/255.0f alpha:1.0f],
                                  @"textColor": [UIColor colorWithRed:128.0f/255.0f green:128.0f/255.0f blue:128.0f/255.0f alpha:1.0f],
                                  @"buttonBackgroundColor": [UIColor colorWithRed:154.0f/255.0f green:159.0f/255.0f blue:153.0f/255.0f alpha:1.0f]
                                  },
                              @{
                                  @"broker":@"tradeking",
                                  @"logo":@"",
                                  @"logoActive": @"1",
                                  @"offerTitle":@"$100 in free trade commission, no minimum amount!",
                                  @"offerDescription": @"Open an Account",
                                  @"accountMinimum": @"",
                                  @"optionsOffer": @"$4.95 + $.65/contract",
                                  @"stocksEtfsOffer": @"$4.95 Online Trades",
                                  @"backgroundColor": [UIColor colorWithRed:50.0f/255.0f green:50.0f/255.0f blue:100.0f/255.0f alpha:1.0f],
                                  @"textColor": [UIColor whiteColor],
                                  @"buttonBackgroundColor": [UIColor colorWithRed:58.0f/255.0f green:149.0f/255.0f blue:202.0f/255.0f alpha:1.0f]
                                  }
                              ];


    // make sure to update this once real data is being used
    UIColor * firstItemBackgroundColor = (UIColor *) [[self.brokerCenterData firstObject] valueForKey:@"backgroundColor"];
    UIColor * lastItemBackgroundColor = (UIColor *) [[self.brokerCenterData lastObject] valueForKey:@"backgroundColor"];
    self.firstItemBackgroundColor = firstItemBackgroundColor;
    self.lastItemBackgroundColor = lastItemBackgroundColor;

    self.brokerCenterImagesLoadingQueue = [[NSMutableArray alloc] init];
    for (NSDictionary * brokerCenterData in self.brokerCenterData) {
        NSNumber * ind = [[NSNumber alloc] initWithInteger:[self.brokerCenterData indexOfObject:brokerCenterData]];
        NSDictionary * queueItem = @{@"logo": [brokerCenterData valueForKey:@"logo"], @"index": ind};
        [self.brokerCenterImagesLoadingQueue addObject: queueItem];
    }

    self.selectedIndex = -1;

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^{
        [self loadImages];
    });
}

-(void) loadImages {
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
//    dispatch_async(queue, ^{

    NSString * logoSrc = [self.brokerCenterImagesLoadingQueue firstObject];
    [self.brokerCenterImagesLoadingQueue removeObjectAtIndex: 0];

    UIImage *img;
    if ([logoSrc isEqualToString:@""]) {

    }

    NSURL *url = [NSURL URLWithString: logoSrc];
    NSData * urlData = [NSData dataWithContentsOfURL:url];
    img = [[UIImage alloc] initWithData: urlData];

    NSMutableArray * brokerCenterImages = [self.brokerCenterImages mutableCopy];
    [brokerCenterImages addObject: img];


    self.brokerCenterImages = [brokerCenterImages copy];

    if (self.brokerCenterImagesLoadingQueue.count > 0) {
        [self loadImages];
    }
//    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.brokerCenterData.count;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedIndex == indexPath.row) {
        return kExpandedHeight;
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

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    TTSDKBrokerCenterTableViewCell * cell = (TTSDKBrokerCenterTableViewCell *)[tableView cellForRowAtIndexPath: indexPath];
    cell.contentView.backgroundColor = cell.contentView.backgroundColor;
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

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    BOOL selected = self.selectedIndex == indexPath.row;

    [cell configureWithData: [self.brokerCenterData objectAtIndex: indexPath.row]];

    if (self.brokerCenterImages.count && indexPath.row <= (self.brokerCenterImages.count-1)) {
        [cell addImage: [self.brokerCenterImages objectAtIndex:indexPath.row]];
        [cell configureSelectedState: selected];
    }

    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //get the cell which is selected
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    //set tempView color of selected cell bcoz when cell selected all view color is gone
    UIView *tempView=[selectedCell viewWithTag:3];
    //set your color whatever you want
    
    NSDictionary * data = (NSDictionary *)[self.brokerCenterData objectAtIndex:indexPath.row];
    tempView.backgroundColor = (UIColor *)[data valueForKey:@"backgroundColor"];
    tempView.opaque = YES;

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
        NSIndexPath * prevPath = [NSIndexPath indexPathForRow: self.selectedIndex inSection: 0];
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
