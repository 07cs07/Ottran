//
//  Ottran.h
//  Ottran
//
//  Created by Balachander M on 23/11/14.

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
