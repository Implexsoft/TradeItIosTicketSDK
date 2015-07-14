//
//  TradeItTicket.m
//  TradingTicket
//
//  Created by Antonio Reyes on 6/22/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "TradeItTicket.h"

@implementation TradeItTicket

+(UIColor *) activeColor {
    return [UIColor colorWithRed:0.0f
                           green:114.0f/255.0f
                            blue:188.0f/255.0f
                           alpha:1.0f];
}

+(UIColor *) baseTextColor {
    return [UIColor darkTextColor];
}

+(UIColor *) tradeItBlue {
    return [UIColor colorWithRed:81.0f/255.0f green:137.0f/255.0f blue:185.0f/255.0f alpha:1.0f];
}

+(UIColor *) tradeItLogoGray {
    return [UIColor colorWithRed:12.0f/255.0f green:52.0f/255.0f blue:85.0f/255.0f alpha:1.0f];
}

+(NSMutableAttributedString *) logoString {
    NSMutableAttributedString * text = [[NSMutableAttributedString alloc] initWithString: @"TRADEIT"];
    
    [text addAttribute:NSForegroundColorAttributeName
                 value:[TradeItTicket tradeItBlue]
                 range:NSMakeRange(0, 5)];
    
    
    [text addAttribute:NSForegroundColorAttributeName
                 value:[TradeItTicket tradeItLogoGray]
                 range:NSMakeRange(5, 2)];
    
    return text;

}

+(NSMutableAttributedString *) logoStringLite {
    NSMutableAttributedString * text = [[NSMutableAttributedString alloc] initWithString: @"TRADEIT"];
    
    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor whiteColor]
                 range:NSMakeRange(0, 5)];
    
    
    [text addAttribute:NSForegroundColorAttributeName
                 value:[TradeItTicket tradeItBlue]
                 range:NSMakeRange(5, 2)];
    
    return text;

}

+(NSString *) getImagePathFromBundle: (NSString *) imageName {
    NSString * bundlePath = [[NSBundle mainBundle] pathForResource:@"TradeItIosTicketSDK" ofType:@"bundle"];
    NSBundle * bundle = [NSBundle bundleWithPath:bundlePath];
    
    NSString *imageExtension = @"";
    NSArray *pngPaths = [bundle pathsForResourcesOfType:imageExtension inDirectory:nil];
    for (NSString *filePath in pngPaths)
    {
        NSString *fileName = [filePath lastPathComponent];
        NSLog(@"%@", fileName);
    }
    
    NSString * imagePath = [bundle pathForResource:imageName ofType:@"png"];
    return imagePath;
}

+(NSString *) splitCamelCase:(NSString *) str {
    NSMutableString * str2 = [NSMutableString string];
    
    for (NSInteger i=0; i < str.length; i++){
        NSString *ch = [str substringWithRange:NSMakeRange(i, 1)];
        if ([ch rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location != NSNotFound) {
            [str2 appendString:@" "];
        }
        [str2 appendString:ch];
    }
    
    return str2.capitalizedString;
}

@end


















