//
//  FlutterTexturePlugin.m
//  flutter_image_view
//
//  Created by johnson_zhong on 2021/8/21.
//

#import "FlutterTexturePlugin.h"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <SDWebImage/SDWebImageDownloader.h>
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImage+MultiFormat.h>
#import <SDWebImage/UIImage+GIF.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

static int standardFramePerSecond = 30;
static bool isReceiveMemoryWarning = NO;

static uint32_t bitmapInfoWithPixelFormatType(OSType inputPixelFormat, bool hasAlpha){
    if (inputPixelFormat == kCVPixelFormatType_32BGRA) {
        uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
        if (!hasAlpha) {
            bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host;
        }
        return bitmapInfo;
    }else if (inputPixelFormat == kCVPixelFormatType_32ARGB) {
        uint32_t bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big;
        return bitmapInfo;
    }else{
        NSLog(@"不支持此格式");
        return 0;
    }
}

// alpha的判断
BOOL CGImageRefContainsAlpha(CGImageRef imageRef) {
    if (!imageRef) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

@interface FlutterTexturePlugin()


@property (nonatomic) CVPixelBufferRef target;

@property (nonatomic, assign) CGSize imageSize;//图片实际大小 px
@property (nonatomic, assign) CGSize screenSize;//图片实际大小 px
@property (nonatomic, copy) void(^updateBlock) (TEXTURECALLBACKTYPE, NSDictionary*);
@property (nonatomic, copy) NSString * requestId;

//下方是展示gif图相关的
@property (nonatomic, strong) CADisplayLink * displayLink;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) SDWebImageDownloadToken *currentToken;
@property (nonatomic, assign) CGFloat frameDuration;//帧率
@property (nonatomic, assign) int currentFrameIndex;//当前展示的第几帧
@property (nonatomic, assign) CGFloat currentFrameDuration;//下一帧要展示的时间差
@property (nonatomic, assign) CFMutableArrayRef cachedTextures;//缓存的纹理
@property (nonatomic, strong) NSMutableArray* cachedImage;//缓存的纹理
@property (nonatomic, assign) int radius;//当前展示的圆角

-(void)handleMemoryWarning:(NSNotification *)notification;

@end



@implementation FlutterTexturePlugin

- (instancetype)initWithImageStr:(NSString*)imageStr imageSize:(CGSize)size radius:(int)radius requestId:(NSString *)requestId callback:(void(^) (TEXTURECALLBACKTYPE, NSDictionary*)) callback{
    self = [super init];
    if (self){
        _updateBlock = callback;
        _requestId = requestId;
        _images = [NSArray array];
        _cachedImage = [NSMutableArray array];
        _cachedTextures = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
        self.screenSize = [[UIScreen mainScreen] bounds].size;
        self.radius = radius;
        if (size.width != 0 && size.height != 0) self.imageSize = size;
        if ([imageStr hasPrefix:@"http://"]||[imageStr hasPrefix:@"https://"]) {
            [self loadImageWithStrFromWeb:imageStr];
        } else {
            [self loadImageWithStrForLocal:imageStr];
        }
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name: UIApplicationDidEnterBackgroundNotification object:nil];
    return self;
}

- (CVPixelBufferRef)copyPixelBuffer {
    if ([_images count] >= 1) {
        long cachedCount = CFArrayGetCount(_cachedTextures);
        UIImage *image = [_images objectAtIndex:_currentFrameIndex];
        NSInteger index = [_cachedImage indexOfObject:image];
        CVPixelBufferRef target = (index >= 0 && cachedCount > index) ? (CVPixelBufferRef)CFArrayGetValueAtIndex(_cachedTextures, index) : NULL;
        if (target == NULL) {
            if (!isReceiveMemoryWarning && cachedCount < 3 * standardFramePerSecond) {
                target = [self CVPixelBufferRefFromUiImage:image];
                CFArrayAppendValue(_cachedTextures, target);
                [_cachedImage addObject:image];
                return CVPixelBufferRetain(target);
            }else {
                CVPixelBufferRelease(_target);
                _target = [self CVPixelBufferRefFromUiImage:[_images objectAtIndex:_currentFrameIndex]];
                return CVPixelBufferRetain(_target);
            }
        }else {
            return CVPixelBufferRetain(target);
        }
    }else {
        return  nil;
    }
}

#pragma mark notification
- (void)handleMemoryWarning:(NSNotification *)notification{
    isReceiveMemoryWarning = YES;
}

- (void)didEnterBackground:(NSNotification *)notification{
    [_displayLink setPaused:YES];
}

- (void)didBecomeActive:(NSNotification *)notification{
    [_displayLink setPaused:NO];
}

-(void)dispose{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.displayLink.paused = YES;
    [self.displayLink invalidate];
    self.displayLink = nil;
    if (_currentToken) [_currentToken cancel];
    if (_target) CVPixelBufferRelease(_target);
    for (int i = 0; i < CFArrayGetCount(_cachedTextures); i++) {
        CVPixelBufferRelease((CVPixelBufferRef)CFArrayGetValueAtIndex(_cachedTextures, i));
    }
    CFArrayRemoveAllValues(_cachedTextures);
    CFRelease(_cachedTextures);
    [_cachedImage removeAllObjects];
    _images = nil;
    _target = nil;
    
}

// 此方法能还原真实的图片
- (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img {
    if (!img) return nil;
    
    CGImageRef image = [img CGImage];
    CGFloat frameWidth = _imageSize.width;
    CGFloat frameHeight = _imageSize.height;

    BOOL hasAlpha = CGImageRefContainsAlpha(image);
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             empty, kCVPixelBufferIOSurfacePropertiesKey,
                             nil];
    CVPixelBufferRef target;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameWidth, frameHeight, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef) options, &target);
    NSParameterAssert(status == kCVReturnSuccess && target != NULL);
    
    CVPixelBufferLockBaseAddress(target, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(target);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    uint32_t bitmapInfo = bitmapInfoWithPixelFormatType(kCVPixelFormatType_32BGRA, (bool)hasAlpha);
    CGContextRef context = CGBitmapContextCreate(pxdata, frameWidth, frameHeight, 8, CVPixelBufferGetBytesPerRow(target), rgbColorSpace, bitmapInfo);
    NSParameterAssert(context);
    
    if (_radius > 0){
        CGContextSetInterpolationQuality(context, kCGInterpolationLow);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, frameWidth, frameHeight) cornerRadius: _radius];
        CGContextAddPath(context, path.CGPath);
        CGContextClip(context);
        [path closePath];
    }
    
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, frameWidth, frameHeight), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(target, 0);
    return target;
}

#pragma mark - image
-(void)loadImageWithStrFromWeb:(NSString*)imageStr{
    _updateBlock(ONPROGRESS, @{@"progress": @"0.0", @"requestId": _requestId});
    __weak typeof(FlutterTexturePlugin*) weakSelf = self;
    [[SDImageCache sharedImageCache] diskImageDataQueryForKey:imageStr completion:^(NSData * _Nullable data) {
        if (data) {
            weakSelf.updateBlock(ONPROGRESS, @{@"progress": @"0.1", @"requestId": weakSelf.requestId});
            [weakSelf loadImage:[UIImage sd_imageWithGIFData:data]];
            weakSelf.updateBlock(ONPROGRESS, @{@"progress": @"0.9", @"requestId": weakSelf.requestId});
            weakSelf.updateBlock(ONDONE, @{@"requestId": weakSelf.requestId});
        } else {
            weakSelf.currentToken = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:imageStr] options:0 context:nil progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                weakSelf.updateBlock(ONPROGRESS, @{@"progress": [NSString stringWithFormat:@"%f", (float)receivedSize/expectedSize], @"requestId": weakSelf.requestId});
            } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                if (error) {
                    weakSelf.updateBlock(ONERROR, @{@"error": [error description], @"requestId": weakSelf.requestId});
                    return;
                }
                if (!image) return;
                [[SDImageCache sharedImageCache] storeImage:image imageData:data forKey:imageStr cacheType:SDImageCacheTypeDisk completion:nil];
                [weakSelf loadImage:image];
                weakSelf.updateBlock(ONDONE, @{@"requestId": weakSelf.requestId});
            }];
        }
    }];
}

-(void)loadImageWithStrForLocal:(NSString*)imageStr{
    _updateBlock(ONPROGRESS, @{@"progress": @"0.0", @"requestId": _requestId});
    UIImage *image = [UIImage imageNamed:imageStr];
    if (image) {
        [self loadImage:image];
        _updateBlock(ONPROGRESS, @{@"progress": @"0.9", @"requestId": _requestId});
        _updateBlock(ONDONE, @{@"requestId": _requestId});
        return;
    }
    image = [UIImage imageWithContentsOfFile:imageStr];
    if (image) {
        [self loadImage:image];
        _updateBlock(ONPROGRESS, @{@"progress": @"0.9", @"requestId": _requestId});
        _updateBlock(ONDONE, @{@"requestId": _requestId});
        return;
    }
    
}

-(void)loadImage:(UIImage *)image {
    if (_imageSize.height != 0 && _imageSize.height != 0) {
        
    }else if (image.size.width > _screenSize.width || image.size.height > _screenSize.height) {
        CGFloat factor = MAX(image.size.width / _screenSize.width, image.size.height / _screenSize.height);
        _imageSize = CGSizeMake(image.size.width / factor, image.size.height / factor);
    }else {
        _imageSize = image.size;
    }
    if (image.images.count > 1 && image.duration > 0) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:[image images]];
        CGFloat duration = image.duration*1.0;
        CGFloat framePerSecond = [array count] / duration;
        if (framePerSecond > standardFramePerSecond) {
            _images = [self filterRedundanceFrame:array framePerSecond:framePerSecond];
            _frameDuration = duration/[_images count];
        }else {
            _images = [NSArray arrayWithArray:array];
            _frameDuration = duration/[_images count];
        }
        [self startDisplay];
    } else {
        _images = [NSArray arrayWithObject:image];
        _currentFrameIndex = 0;
        if (_updateBlock) _updateBlock(UPDATETEXTURE, @{});
    }
}


- (NSArray *)filterRedundanceFrame:(NSMutableArray *)frames framePerSecond:(CGFloat)framePerSecond {
    if (framePerSecond - standardFramePerSecond >= standardFramePerSecond) {
//                从所有帧中抽取可用帧
        NSMutableArray *result = [NSMutableArray array];
        int gap = framePerSecond / standardFramePerSecond;
        for (int i = 0; i < [frames count]; i++) {
            if (i == 0) {
                [result addObject: [frames objectAtIndex:i]];
            }else if (i % gap == 0) {
                [result addObject: [frames objectAtIndex:i]];
            }
        }
        return result;
    }else {
//                从所有帧中移除多余帧
        NSMutableArray *result = [NSMutableArray array];
        int gap = standardFramePerSecond / (framePerSecond - standardFramePerSecond)  + 1;
        for (int i = 0; i < [frames count]; i++) {
            if (i == 0) {
                [result addObject:[frames objectAtIndex:i]];
            }else if (i % gap == 0) {
                
            }else {
                [result addObject:[frames objectAtIndex:i]];
            }
        }
        return result;
    }
}

- (NSMutableArray *)filterSameFrame:(NSMutableArray *)frames {
    if (!frames || [frames count] <= 0) return frames;
    NSSet *set = [NSSet setWithArray:frames];
    return [NSMutableArray arrayWithArray:[set allObjects]];
}

- (void)startDisplay {
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)update:(CADisplayLink*)displayLink{
    _currentFrameDuration -= displayLink.duration;
    if (_currentFrameDuration<=0) {
        _currentFrameIndex += 1;
        if (_currentFrameIndex >= [_images count]) _currentFrameIndex = 0;
        _currentFrameDuration = _frameDuration;
        _updateBlock(UPDATETEXTURE, @{});
    }
}

@end
