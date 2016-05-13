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
#import "TradeItEmsUtils.h"

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
        self.brokerCenterLogoImages = [[NSArray alloc] init];
        self.brokerCenterButtonViews = [[NSMutableArray alloc] init];

        globalTicket = [TTSDKTradeItTicket globalTicket];
        imageLoadingQueue = [[NSMutableArray alloc] init];
    }

    return self;
}

-(void) getBrokerCenter {
    self.isRetrievingBrokerCenter = YES;
    self.brokerCenterLoaded = NO;

    TradeItPublisherService * publisherService = [[TradeItPublisherService alloc] initWithConnector:globalTicket.connector];
    TradeItBrokerCenterRequest * brokerRequest = [[TradeItBrokerCenterRequest alloc] init];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);

    dispatch_async(queue, ^{
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

                [self loadWebViews];
                [self loadImages];
            }
        }];
    });
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

-(void) loadWebViews {
    for (TradeItBrokerCenterBroker *broker in self.brokerCenterBrokers) {

        UIWebView * buttonWebView = [[UIWebView alloc] initWithFrame:CGRectZero];

        NSString * urlStr = [NSString stringWithFormat:@"%@publisherad/brokerCenterPromptAdView?apiKey=%@-key&broker=%@", getEmsBaseUrl(globalTicket.connector.environment), globalTicket.connector.apiKey, broker.broker];
        [buttonWebView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString:urlStr]]];

        [self.brokerCenterButtonViews addObject: @{@"broker": broker.broker, @"webView": buttonWebView}];
    }
}


@end
