**ஒற்றன் - Ottran** Tamil meaning of Scout

**Ottran** is a Objective C implementation of [ImageScout](https://github.com/kaishin/ImageScout), which works in swift too.
It allows you to find the size and type of a remote image by downloading as little as possible.

#### Why?

Sometimes you need to know the size of a remote image before downloading it, such as
using a custom layout in a `UICollectionView`.

#### How?

Ottran parses the image data as it is downloaded. As soon as it finds out the size and type of image,
it stops the download. The downloaded data is below 60 KB in most cases.

#### Install

Just copy and paste those Ottran.h(&).m files to your project.

#### Usage

The only method you will be using is `scoutImageWithURI()`, with the following full signature:

```objc
- (void)scoutImageWithURI:(NSString *)uri andOttranCompletion:(OttranCompletionBlock)completion;

(^OttranCompletionBlock) (NSError *, CGSize, OttranImageType);
```

Here's an example:

```objc
    Ottran *anScouter = [[Ottran alloc] init];

    [anScouter scoutImageWithURI:path andOttranCompletion:^(NSError *error, CGSize size, OttranImageType imageType) {
            if (error) {
                NSLog(@"Error = %@", error);
            } else {
            	NSLog(@"Image Size = %@",NSStringFromCGSize(size));
                switch (imageType) {
                    case GIF: NSLog(@"Image Type = GIF); break;
                    case PNG: NSLog(@"Image Type = PNG); break;
                    case JPEG: NSLog(@"Image Type = JPEG); break;
                    case Unsupported: NSLog(@"Image Type = UnSupported"); break;
                    default: break;
                }
            }
        }];
```

If the image is not successfully parsed, the error will contain more info about the reason.
In that case, the size is going to be `CGSizeZero` and the type `Unsupported`.

- Error code **100**: Invalid URI parameter.
- Error code **101**: Image is corrput or malformatted.
- Error code **102**: Not an image or unsopported image format URL.

#### Compatibility

- iOS 6.0 and above.
- Compiles with Xcode 5 and above.

#### License

See LICENSE.
