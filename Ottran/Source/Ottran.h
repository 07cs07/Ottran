//
//  Ottran.h
//  Ottran
//
//  Created by Balachander M on 23/11/14.
//  Copyright (c) 2014 Balachander M. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OttranImageType) {
    GIF,
    PNG,
    JPEG,
    BMP,
    Unsupported
};

typedef void (^OttranCompletionBlock) (NSError *, CGSize, OttranImageType);

@interface Ottran : NSObject

- (void)scoutImageWithURI:(NSString *)uri andOttranCompletion:(OttranCompletionBlock)completion;
@end
