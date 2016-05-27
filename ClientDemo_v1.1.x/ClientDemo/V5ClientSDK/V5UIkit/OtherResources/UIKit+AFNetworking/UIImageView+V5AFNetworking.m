// UIImageView+AFNetworking.m
//
// Copyright (c) 2013-2014 AFNetworking (http://afnetworking.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "UIImageView+V5AFNetworking.h"

#import <objc/runtime.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import "V5AFHTTPRequestOperation.h"
#import "V5Macros.h"

V5KW_FIX_CATEGORY_BUG_M(UIImageView_V5AFNetworking)

@interface V5AFImageCache : NSCache <V5AFImageCache>
@end

#pragma mark -

@interface UIImageView (_V5AFNetworking)
@property (readwrite, nonatomic, strong, setter = af_setImageRequestOperation:) V5AFHTTPRequestOperation *af_imageRequestOperation;
@end

@implementation UIImageView (_V5AFNetworking)

+ (NSOperationQueue *)af_sharedImageRequestOperationQueue {
    static NSOperationQueue *_af_sharedImageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_sharedImageRequestOperationQueue = [[NSOperationQueue alloc] init];
        _af_sharedImageRequestOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    });

    return _af_sharedImageRequestOperationQueue;
}

- (V5AFHTTPRequestOperation *)af_imageRequestOperation {
    return (V5AFHTTPRequestOperation *)objc_getAssociatedObject(self, @selector(af_imageRequestOperation));
}

- (void)af_setImageRequestOperation:(V5AFHTTPRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, @selector(af_imageRequestOperation), imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark -

@implementation UIImageView (V5AFNetworking)
@dynamic imageResponseSerializer;

+ (id <V5AFImageCache>)sharedImageCache {
    static V5AFImageCache *_af_defaultImageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _af_defaultImageCache = [[V5AFImageCache alloc] init];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * __unused notification) {
            [_af_defaultImageCache removeAllObjects];
        }];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    return objc_getAssociatedObject(self, @selector(sharedImageCache)) ?: _af_defaultImageCache;
#pragma clang diagnostic pop
}

+ (void)setSharedImageCache:(id <V5AFImageCache>)imageCache {
    objc_setAssociatedObject(self, @selector(sharedImageCache), imageCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (id <V5AFURLResponseSerialization>)imageResponseSerializer {
    static id <V5AFURLResponseSerialization> _af_defaultImageResponseSerializer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _af_defaultImageResponseSerializer = [V5AFImageResponseSerializer serializer];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    return objc_getAssociatedObject(self, @selector(imageResponseSerializer)) ?: _af_defaultImageResponseSerializer;
#pragma clang diagnostic pop
}

- (void)setImageResponseSerializer:(id <V5AFURLResponseSerialization>)serializer {
    objc_setAssociatedObject(self, @selector(imageResponseSerializer), serializer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (void)setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url placeholderImage:nil failureImage:nil];
}

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
           failureImage:(UIImage *)failureImage
{
    if (url == nil) {
        if (failureImage) {
            [self setImage:failureImage];
        } else if (placeholderImage) {
            [self setImage:placeholderImage];
        }
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    __weak __typeof(self)weakSelf = self;
    [self setImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (failureImage) {
            strongSelf.image = failureImage;
        }
    }];
}

- (void)setImageWithURLRequest:(NSURLRequest *)urlRequest
              placeholderImage:(UIImage *)placeholderImage
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self cancelImageRequestOperation];

    UIImage *cachedImage = [[[self class] sharedImageCache] cachedImageForRequest:urlRequest];
    if (cachedImage) {
        if (success) {
            success(nil, nil, cachedImage);
        } else {
            self.image = cachedImage;
        }

        self.af_imageRequestOperation = nil;
    } else {
        if (placeholderImage) {
            self.image = placeholderImage;
        }
        
        __weak __typeof(self)weakSelf = self;
        self.af_imageRequestOperation = [[V5AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
        [self.af_imageRequestOperation.securityPolicy setAllowInvalidCertificates:YES];
        self.af_imageRequestOperation.responseSerializer = self.imageResponseSerializer;
        [self.af_imageRequestOperation setCompletionBlockWithSuccess:^(V5AFHTTPRequestOperation *operation, id responseObject) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if ([[urlRequest URL] isEqual:[strongSelf.af_imageRequestOperation.request URL]]) {
                if (success) {
                    success(urlRequest, operation.response, responseObject);
                } else if (responseObject) {
                    strongSelf.image = responseObject;
                }

                if (operation == strongSelf.af_imageRequestOperation){
                        strongSelf.af_imageRequestOperation = nil;
                }
            }

            [[[strongSelf class] sharedImageCache] cacheImage:responseObject forRequest:urlRequest];
        } failure:^(V5AFHTTPRequestOperation *operation, NSError *error) {
            V5Log(@"---- V5AFHTTPRequestOperation error:%@ ----", [error description]);
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if ([[urlRequest URL] isEqual:[strongSelf.af_imageRequestOperation.request URL]]) {
                if (failure) {
                    failure(urlRequest, operation.response, error);
                }

                if (operation == strongSelf.af_imageRequestOperation){
                        strongSelf.af_imageRequestOperation = nil;
                }
            }
        }];

        [[[self class] af_sharedImageRequestOperationQueue] addOperation:self.af_imageRequestOperation];
    }
}

- (void)cancelImageRequestOperation {
    [self.af_imageRequestOperation cancel];
    self.af_imageRequestOperation = nil;
}

+ (void)clearImageCache {
    // 清空图片缓存
    V5AFImageCache *cache = (V5AFImageCache *)[UIImageView sharedImageCache];
    [cache removeAllObjects];
}

@end

#pragma mark -

static inline NSString * V5AFImageCacheKeyFromURLRequest(NSURLRequest *request) {
    return [[request URL] absoluteString];
}

@implementation V5AFImageCache

- (UIImage *)cachedImageForRequest:(NSURLRequest *)request {
    switch ([request cachePolicy]) {
        case NSURLRequestReloadIgnoringCacheData:
        case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
            return nil;
        default:
            break;
    }

	return [self objectForKey:V5AFImageCacheKeyFromURLRequest(request)];
}

- (void)cacheImage:(UIImage *)image
        forRequest:(NSURLRequest *)request
{
    if (image && request) {
        [self setObject:image forKey:V5AFImageCacheKeyFromURLRequest(request)];
    }
}

@end

#endif
