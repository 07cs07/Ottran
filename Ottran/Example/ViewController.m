//
//  ViewController.m
//  Ottran
//
//  Created by Balachander M on 23/11/14.

#import "ViewController.h"
#import "Ottran.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    Ottran *anScouter = [[Ottran alloc] init];
    
    NSArray *paths = @[@"http://fc07.deviantart.net/fs71/i/2011/226/6/9/india_flag_by_ninjasoar-d46jzi7.png",
                       @"http://www.pdms-photography.com/images/stories/Portraits_Pets/childrens_portraits_photography.png",
                       @"http://myanamika.com/wp-content/uploads/2014/08/india-flag-animate.gif"];
    
    for (NSString *path in paths) {
        [anScouter scoutImageWithURI:path andOttranCompletion:^(NSError *error, CGSize size, OttranImageType imageType) {
            
            if (error) {
                NSLog(@"Error = %@", error);
            } else {
                switch (imageType) {
                    case GIF: NSLog(@"Image Type = GIF & Image Size = %@",NSStringFromCGSize(size));
                        break;
                    case PNG: NSLog(@"Image Type = PNG & Image Size = %@",NSStringFromCGSize(size));
                        break;
                    case JPEG: NSLog(@"Image Type = JPEG & Image Size = %@",NSStringFromCGSize(size));
                        break;
                    case BMP: NSLog(@"Image Type = BMP & Image Size = %@",NSStringFromCGSize(size));
                        break;
                    case Unsupported: NSLog(@"Image Type = UnSupported");
                        break;
                    default:
                        break;
                }
            }
        }];
    }
}

@end
