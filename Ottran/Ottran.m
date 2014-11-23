//
//  Ottran.m
//  Ottran
//
//  Created by Balachander M on 23/11/14.

#import "Ottran.h"
NSString *const unsupportedFormatErrorMessage = @"Unsupported image format. ImageScout only supports PNG, GIF, and JPEG.";
NSString *const unableToParseErrorMessage = @"Scouting operation failed. The remote image is likely malformated or corrupt.";
NSString *const invalidURIErrorMessage = @"Invalid URI parameter.";
NSString *const errorDomain = @"ImageScoutErrorDomain";

@protocol OttranDataDelegate <NSObject>

- (void)didReceiveData:(NSData *)data onConnection:(NSURLConnection *)connection;
- (void)didCompleteWithError:(NSError *)error onConnection:(NSURLConnection *)connection;

@end

@class OttranConnectionDelegate;
@interface Ottran () <OttranDataDelegate>
{
    NSOperationQueue *queue;
    NSMutableDictionary *operations;
}

@property (nonatomic, retain) OttranConnectionDelegate *connectionDelegate;
+ (NSError *)errorWithMessag:(NSString *)message andCode:(int)code;
@end

@interface OttranConnectionDelegate : NSObject <NSURLConnectionDelegate>
@property (nonatomic, weak) id <OttranDataDelegate> delegate;

- (instancetype)initWithDelegate:(id)delegate;
@end

@implementation OttranConnectionDelegate

- (instancetype)initWithDelegate:(id)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    if (_delegate && [_delegate respondsToSelector:@selector(didReceiveData:onConnection:)]) {
        [_delegate didReceiveData:data onConnection:connection];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    if (_delegate && [_delegate respondsToSelector:@selector(didCompleteWithError:onConnection:)]) {
        [_delegate didCompleteWithError:error onConnection:connection];
    }
}

@end


typedef struct PNGSize {
    UInt32 width;
    UInt32 height;
} PNGSize;

typedef struct JPEGSize {
    UInt16 height;
    UInt16 width;
} JPEGSize;

typedef struct GIFSize {
    UInt16 width;
    UInt16 height;
} GIFSize;

typedef NS_ENUM (NSInteger, JPEGHeaderSegment) {
    NextSegment,
    SOFSegment,
    SkipSegment,
    ParseSegment,
    EOISegment
};

#pragma mark - Parser

@interface Parser : NSObject

+ (OttranImageType)imageTypeFromData:(NSData *)data;
+ (CGSize)imageSizeFromData:(NSData *)imageData ofImageType:(OttranImageType)imageType;

@end

@implementation Parser

#pragma mark - Class Methods

+ (OttranImageType)imageTypeFromData:(NSData *)data {
    int sampleLength = 2;
    if (data.length < sampleLength) { return Unsupported; }
    UInt16 length = 0;
    [data getBytes:&length range:NSMakeRange(0, sampleLength)];
    
    switch (CFSwapInt16(length)) {
        case 0xFFD8: return JPEG; break;
        case 0x8950: return PNG; break;
        case 0x4749: return GIF; break;
        default: return Unsupported; break;
    }
}

+ (CGSize)imageSizeFromData:(NSData *)imageData ofImageType:(OttranImageType)imageType {
    switch (imageType) {
        case GIF:  return GiffSizeFromData(imageData);
            break;
        case PNG:  return PNGSizeFromData(imageData);
            break;
        case JPEG: return JPEGSizeFromData(imageData);
            break;
        case Unsupported: return CGSizeZero;
            break;
        default:  return CGSizeZero;
            break;
    }
}

#pragma mark - GIFF

CGSize GiffSizeFromData(NSData *data) {
    if (data.length < 11) { return CGSizeZero; }
    
    GIFSize imageSize = {0, 0};
    [data getBytes:&imageSize range:NSMakeRange(6, 4)];
    return CGSizeMake(imageSize.width, imageSize.height);
}

#pragma mark - PNG

CGSize PNGSizeFromData(NSData *data) {
    if (data.length < 25) { return CGSizeZero; }
    
    PNGSize imageSize = {0, 0};
    [data getBytes:&imageSize range:NSMakeRange(16, 8)];
    return CGSizeMake(CFSwapInt32(imageSize.width), CFSwapInt32(imageSize.height));
}

#pragma mark - JPEG

CGSize JPEGSizeFromData(NSData *data) {
    NSInteger offset = 2;
    CGSize size;
    if (data.length <= offset) { size = CGSizeZero; }
    else {
        size = parseJPEGData(data,offset,NextSegment);
    }
    return size;
}

CGSize parseJPEGData(NSData *data, NSInteger offset, JPEGHeaderSegment segment) {
    if (segment == EOISegment
        || (data.length <= offset + 1)
        || ((data.length <= offset + 2) && segment == SkipSegment)
        || ((data.length <= offset + 7) && segment == ParseSegment)) {
        
        return CGSizeZero;
    }
    
    switch (segment) {
        case NextSegment: {
            NSInteger newOffset = offset + 1;
            UInt16 byte = 0x0;
            [data getBytes:&byte range:NSMakeRange(newOffset, 1)];
            if (byte == 0xFF) {
                return parseJPEGData(data, newOffset, SOFSegment);
            } else {
                return parseJPEGData(data, newOffset, NextSegment);
            }
        }
            break;
        case SOFSegment: {
            NSInteger newOffset = offset + 1;
            UInt32 byte = 0x0;
            [data getBytes:&byte range:NSMakeRange(newOffset, 1)];
            
            if (0xEF >= byte && byte >= 0xE0 ) {
                return parseJPEGData(data, newOffset, SkipSegment);
            } else if ((0xC3 >= byte && byte >= 0xC0) || (0xC7 >= byte && byte >= 0xC5) || (0xCB >= byte && byte >= 0xC9) || (0xCF >= byte && byte >= 0xCD)) {
                return parseJPEGData(data, newOffset, ParseSegment);
            } else if (byte == 0xFF) {
                return parseJPEGData(data, newOffset, SOFSegment);
            } else if (byte == 0xD9) {
                return parseJPEGData(data, newOffset, EOISegment);
            } else {
                return parseJPEGData(data, newOffset, SkipSegment);
            }
        }
            break;
        case SkipSegment: {
            
            UInt16 length;
            [data getBytes:&length range:NSMakeRange(offset + 1, 2)];
            
            NSInteger newOffset = offset + CFSwapInt16(length) - 1;
            return parseJPEGData(data, newOffset, NextSegment);
        }
            break;
        case ParseSegment: {
            JPEGSize size = {0, 0};
            [data getBytes:&size range:NSMakeRange(offset + 4, 4)];
            return CGSizeMake(CFSwapInt16(size.width), CFSwapInt16(size.height));
        }
            break;
        default:
            return CGSizeZero;
            break;
    }
}

@end

@interface OttranOperation : NSOperation
{
    NSMutableData *mutableData;
    NSURLConnection *dataTask;
}

@property (nonatomic, weak) NSError *error;
@property (nonatomic) OttranImageType type;
@property (nonatomic) CGSize size;

- (instancetype)initWithURLConnection:(NSURLConnection *)connection;
@end

@implementation OttranOperation

- (instancetype)initWithURLConnection:(NSURLConnection *)connection {
    self = [super init];
    if (self) {
        _type = Unsupported;
        _size = CGSizeZero;
        mutableData = [NSMutableData new];
        dataTask = connection;
    }
    return self;
}

- (void)start {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if (!self.isCancelled) { [dataTask start]; }
}

- (void)cancel {
    [super cancel];
    [dataTask cancel];
}

- (void)parse {
    NSData *dataCopy = [mutableData copy];
    _type = [Parser imageTypeFromData:dataCopy];
    
    if (_type != Unsupported) {
        _size = [Parser imageSizeFromData:dataCopy ofImageType:_type];
        if (!CGSizeEqualToSize(_size, CGSizeZero)) { [self complete]; }
    } else if (dataCopy.length > 2) {
        _error = [Ottran errorWithMessag:unsupportedFormatErrorMessage andCode:102];
        [self complete];
    }
}

- (void)complete {
    if (self.completionBlock) {
        self.completionBlock();
    }
    [self cancel];
}

- (void)appendData:(NSData *)data {
    if (!self.isCancelled) { [mutableData appendData:data]; }
    
    if (data.length < 2 ) { return; }
    
    if (!self.isCancelled) { [self parse]; }
}

- (void)terminateWithError:(NSError *)completionError {
    _error = completionError;
}

@end

@implementation Ottran
- (instancetype)init {
    self = [super init];
    if (self) {
        queue = [NSOperationQueue new];
        operations = [NSMutableDictionary new];
        _connectionDelegate = [[OttranConnectionDelegate alloc] init];
        _connectionDelegate.delegate = self;
    }
    return self;
}

/**
 *    Takes a URL string and a completion block and returns void.
 *    The completion block takes an optional error, a size, and an image type,
 *    and returns void.
 *
 *  @param uri        URL string of the source image
 *  @param completion OttranCompletionBlock that has Optional error (which returns nil when Ottran can image parsed successfully), size and image type
 */
- (void)scoutImageWithURI:(NSString *)uri andOttranCompletion:(OttranCompletionBlock)completion
{
    NSURL *url = [NSURL URLWithString:uri];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    if (request) {
        NSURLConnection *taskConnection = [[NSURLConnection alloc] initWithRequest:request delegate:_connectionDelegate startImmediately:NO];
        
        OttranOperation *_operation = [[OttranOperation alloc] initWithURLConnection:taskConnection];
        __weak OttranOperation *operation = _operation;
        [operation setCompletionBlock:^(){
            if (completion) {
                completion(operation.error, operation.size, operation.type);
                [operations removeObjectForKey:uri];
            }
        }];
        [self addOperation:operation withURI:uri];
    } else {
        NSError *error = [Ottran errorWithMessag:invalidURIErrorMessage andCode:100];
        if (completion) {
            completion(error, CGSizeZero, Unsupported);
        }
    }
}

#pragma mark - Class Method

+ (NSError *)errorWithMessag:(NSString *)message andCode:(int)code {
    return [NSError errorWithDomain:errorDomain code:code userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(message, nil)}];
}

#pragma mark -  Delegates

- (void)didReceiveData:(NSData *)data onConnection:(NSURLConnection *)connection {
    NSString *requestURL = [connection.currentRequest.URL absoluteString];
    if (requestURL) {
        OttranOperation *operation = operations[requestURL];
        if (operation) {
            [operation appendData:data];
        }
    }
}

- (void)didCompleteWithError:(NSError *)error onConnection:(NSURLConnection *)connection {
    NSString *requestURL = [connection.currentRequest.URL absoluteString];
    if (requestURL) {
        NSError *completionError = [Ottran errorWithMessag:unableToParseErrorMessage andCode:101];
        OttranOperation *operation = operations[requestURL];
        if (operation) {
            [operation terminateWithError:completionError];
        }
    }
}

#pragma mark - Private Method

- (void)addOperation:(OttranOperation *)operation withURI:(NSString *)uri {
    operations[uri] = operation;
    [queue addOperation:operation];
}


@end
