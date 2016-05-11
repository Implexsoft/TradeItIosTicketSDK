//
//  TTSDKAdService.m
//  TradeItIosTicketSDK
//
//  Created by Daniel Vaughn on 5/9/16.
//  Copyright © 2016 Antonio Reyes. All rights reserved.
//

#import "TTSDKAdService.h"
#import "TradeItBrokerCenterRequest.h"
#import "TradeItPublisherService.h"
#import "TTSDKTradeItTicket.h"

@interface TTSDKAdService() {
    TTSDKTradeItTicket * globalTicket;
    NSMutableArray * imageLoadingQueue;
}

@property NSArray * data;
@property NSArray * brokerCenterLogoImages;

@end

@implementation TTSDKAdService

- (id)init {
    if (self = [super init]) {
        globalTicket = [TTSDKTradeItTicket globalTicket];
        self.brokerCenterLogoImages = [[NSArray alloc] init];
        imageLoadingQueue = [[NSMutableArray alloc] init];
    }

    return self;
}

-(void) getBrokerCenter {
    self.isRetrievingBrokerCenter = YES;
    self.brokerCenterLoaded = NO;

    TradeItPublisherService * publisherService = [[TradeItPublisherService alloc] initWithConnector:globalTicket.connector];
    TradeItBrokerCenterRequest * brokerRequest = [[TradeItBrokerCenterRequest alloc] init];

    [publisherService getBrokerCenter:brokerRequest withCompletionBlock:^(TradeItResult *res) {
        self.brokerCenterLoaded = YES;
        self.isRetrievingBrokerCenter = NO;

        if ([res isKindOfClass:TradeItErrorResult.class]) {
            self.brokerCenterActive = NO; // disable the broker center if we can't get the data
        } else {
            TradeItBrokerCenterResult * result = (TradeItBrokerCenterResult *)res;

            self.brokerCenterActive = result.active;
            self.brokerCenterBrokers = result.brokers;

            for (TradeItBrokerCenterBroker * broker in result.brokers) {
                NSMutableDictionary * logoItem = [broker.logo mutableCopy];
                logoItem[@"broker"] = [broker valueForKey:@"broker"];
                
                [imageLoadingQueue addObject:[logoItem copy]];
            }

            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
            dispatch_async(queue, ^{
                [self loadImages];
            });
        }
    }];
}

-(UIImage *) logoImageByBoker:(NSString *)broker {
    if (!self.brokerCenterLogoImages || !self.brokerCenterLogoImages.count) {
        return nil;
    }

    NSDictionary * selectedLogoItem;

    for (NSDictionary * logoItem in self.brokerCenterLogoImages) {
        if (logoItem && [[logoItem valueForKey:@"broker"] isEqualToString:broker]) {
            selectedLogoItem = logoItem;
        }
    }

    if (selectedLogoItem) {
        return [selectedLogoItem valueForKey:@"image"];
    } else {
        return nil;
    }
}

-(void) loadImages {
    NSDictionary * logoItem = [imageLoadingQueue firstObject];
    [imageLoadingQueue removeObjectAtIndex:0];

    UIImage * img;

    NSString * logoSrc = [logoItem valueForKey:@"src"];
    if ([logoSrc isEqualToString:@""]) {
        NSString * imageLocalSrc = [NSString stringWithFormat:@"TradeItIosTicketSDK.bundle/%@_logo.png", [logoItem valueForKey:@"broker"]];
        img = [UIImage imageNamed: imageLocalSrc];

    } else {
        NSURL *url = [NSURL URLWithString: logoSrc];
        NSData * urlData = [NSData dataWithContentsOfURL:url];
        img = [[UIImage alloc] initWithData: urlData];
    }

    if (img) {
        NSMutableArray * mutableImages = [self.brokerCenterLogoImages mutableCopy];
        [mutableImages addObject:@{@"image": img, @"broker": [logoItem valueForKey:@"broker"]}];
        self.brokerCenterLogoImages = [mutableImages copy];
    }

    if (imageLoadingQueue.count) {
        [self loadImages];
    }
}

@end
