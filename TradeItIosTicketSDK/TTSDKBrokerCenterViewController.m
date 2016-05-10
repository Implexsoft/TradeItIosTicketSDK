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

    if (self.ticket.adService.brokerCenterBrokers) {
        self.brokerCenterData = self.ticket.adService.brokerCenterBrokers;
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

//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
//    dispatch_async(queue, ^{
//        [self loadImages];
//    });
}

//-(void) loadImages {
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
//    dispatch_async(queue, ^{
//        for (NSDictionary * queueItem in self.brokerCenterImagesLoadingQueue) {
//            UIImage * img;
//
//            NSDictionary * logo = [queueItem valueForKey:@"logo"];
//
//            if ([[logo valueForKey:@"src"] isEqualToString:@""]) {
//
//                
//
//            } else {
//
//            }
//        }
//
////    NSString * logoSrc = [self.brokerCenterImagesLoadingQueue firstObject];
////    [self.brokerCenterImagesLoadingQueue removeObjectAtIndex: 0];
////
////    UIImage *img;
////    if ([logoSrc isEqualToString:@""]) {
////
////    }
////
////    NSURL *url = [NSURL URLWithString: logoSrc];
////    NSData * urlData = [NSData dataWithContentsOfURL:url];
////    img = [[UIImage alloc] initWithData: urlData];
////
////    NSMutableArray * brokerCenterImages = [self.brokerCenterImages mutableCopy];
////    [brokerCenterImages addObject: img];
////
////
////    self.brokerCenterImages = [brokerCenterImages copy];
////
////    if (self.brokerCenterImagesLoadingQueue.count > 0) {
////        [self loadImages];
////    }
//    });
//}

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

    TradeItBrokerCenterBroker * brokerCenterItem = [self.brokerCenterData objectAtIndex: indexPath.row];
    [cell configureWithBroker: brokerCenterItem];
    UIImage * img = [self.ticket.adService logoImageByBoker: [brokerCenterItem valueForKey:@"broker"]];

    if (img) {
        [cell addImage:img];
    }

    BOOL selected = self.selectedIndex == indexPath.row;
    [cell configureSelectedState: selected];

    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //get the cell which is selected
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    //set tempView color of selected cell because when cell is selected, all view color is gone
    UIView *tempView=[selectedCell viewWithTag:3];
    NSDictionary * data = (NSDictionary *)[self.brokerCenterData objectAtIndex:indexPath.row];
    tempView.backgroundColor = [TTSDKBrokerCenterTableViewCell colorFromArray:[data valueForKey:@"backgroundColor"]];
    tempView.opaque = YES;
    tempView.alpha = 1.0f;

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
