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

@interface FlutterTexturePlugin() {
    BOOL _pixelBuffDecodeFinish;
}


@property (nonatomic) CFMutableArrayRef pixelBuffs;
@property (nonatomic) CVPixelBufferRef target;

@property (nonatomic, assign) CGSize imageSize;//图片实际大小 px
@property (nonatomic, assign) CGSize screenSize;//图片实际大小 px
@property (nonatomic, copy) void(^updateBlock) (void);

//下方是展示gif图相关的
@property (nonatomic, strong) CADisplayLink * displayLink;
@property (nonatomic, strong) NSMutableArray<NSDictionary*> *images;
@property (nonatomic, strong) SDWebImageDownloadToken *currentToken;
@property (nonatomic, assign) int now_index;//当前展示的第几帧
@property (nonatomic, assign) int radius;//当前展示的圆角
@property (nonatomic, assign) CGFloat can_show_duration;//下一帧要展示的时间差

@end



@implementation FlutterTexturePlugin

- (instancetype)initWithImageStr:(NSString*)imageStr imageSize:(CGSize)size radius:(int)radius callback:(void(^) (void)) callback{
    self = [super init];
    if (self){
        _updateBlock = callback;
        self.images = [NSMutableArray array];
        self.screenSize = [[UIScreen mainScreen] bounds].size;
        self.radius = radius;
        if (size.width != 0 && size.height != 0) self.imageSize = size;
        self.pixelBuffs = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
        if ([imageStr hasPrefix:@"http://"]||[imageStr hasPrefix:@"https://"]) {
            [self loadImageWithStrFromWeb:imageStr];
        } else {
            [self loadImageWithStrForLocal:imageStr];
        }
    }
    return self;
}

-(void)dealloc{
//    [[SDWebImageManager sharedManager] provideImageData:<#(nonnull void *)#> bytesPerRow:<#(size_t)#> origin:<#(size_t)#> :<#(size_t)#> size:<#(size_t)#> :<#(size_t)#> userInfo:<#(nullable id)#>]
}

- (CVPixelBufferRef)copyPixelBuffer {
    return (_target && _pixelBuffDecodeFinish) ? CVPixelBufferRetain(_target) : nil;
}

-(void)dispose{
    self.displayLink.paused = YES;
    [self.displayLink invalidate];
    self.displayLink = nil;
    for (int i = 0; i < CFArrayGetCount(_pixelBuffs); i++) {
        CVPixelBufferRelease((CVPixelBufferRef)CFArrayGetValueAtIndex(_pixelBuffs, i));
    }
    CFArrayRemoveAllValues(_pixelBuffs);
    CFRelease(_pixelBuffs);
    if (_currentToken) [_currentToken cancel];
    _pixelBuffs = nil;
    _target = nil;
}

// 此方法能还原真实的图片
- (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img {
    _pixelBuffDecodeFinish = NO;
    if (!img) {
        _pixelBuffDecodeFinish = YES;
        return nil;
    }
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
    
    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, frameWidth, frameHeight) cornerRadius: _radius];
    CGContextAddPath(context, path.CGPath);
    CGContextClip(context);
    
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, frameWidth, frameHeight), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(target, 0);
    _pixelBuffDecodeFinish = YES;
    return target;
}

#pragma mark - image
-(void)loadImageWithStrForLocal:(NSString*)imageStr{
    UIImage *image = [UIImage imageNamed:imageStr];
    if (!image) return;
    if (self.imageSize.height != 0 && self.imageSize.height != 0) {
        
    }else if (image.size.width > self.screenSize.width || image.size.height > self.screenSize.height) {
        CGFloat factor = MAX(image.size.width / self.screenSize.width, image.size.height / self.screenSize.height);
        self.imageSize = CGSizeMake(image.size.width / factor, image.size.height / factor);
    }else {
        self.imageSize = image.size;
    }
    if (image.images.count > 1) {
        self.images = [NSMutableArray array];
        [self sd_GIFImagesWithLocalNamed:imageStr];
    } else {
        self.target = [self CVPixelBufferRefFromUiImage:image];
        CFArrayAppendValue(_pixelBuffs, self.target);
    }
}

-(void)loadImageWithStrFromWeb:(NSString*)imageStr{
    __weak typeof(FlutterTexturePlugin*) weakSelf = self;
    
    [[SDImageCache sharedImageCache] diskImageDataQueryForKey:imageStr completion:^(NSData * _Nullable data) {
        if (data) {
            [weakSelf loadImage:[UIImage sd_imageWithGIFData:data]];
        } else {
            weakSelf.currentToken = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:imageStr] completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                if (!image) return;
                [[SDImageCache sharedImageCache] storeImage:image imageData:data forKey:imageStr cacheType:SDImageCacheTypeDisk completion:nil];
                [weakSelf loadImage:image];
            }];
        }
    }];
}

-(void)loadImage:(UIImage *)image {
    if (_imageSize.height != 0 && _imageSize.height != 0) {
        
    }else if (image.size.width > _screenSize.width || image.size.height > _screenSize.height) {
        CGFloat factor = MAX(image.size.width / _screenSize.width, image.size.height / _screenSize.height);
        _imageSize = CGSizeMake(image.size.width / factor, image.size.height / factor);
    }else {
        _imageSize = image.size;
    }
    if (image.images.count > 1) {
        for (UIImage * uiImage in image.images) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
                @"duration":@(image.duration*1.0/image.images.count),
                @"image":uiImage
            }];
            [_images addObject:dic];
        }
        if (_pixelBuffs != nil) [self startGifDisplay];
    } else {
        if (_pixelBuffs != nil) {
            _target = [self CVPixelBufferRefFromUiImage:image];
            CFArrayAppendValue(_pixelBuffs, _target);
            if (_updateBlock) _updateBlock();
            
        }
    }
}

-(void)updategif:(CADisplayLink*)displayLink{
    if (self.images.count==0) {
        self.displayLink.paused = YES;
        [self.displayLink invalidate];
        self.displayLink = nil;
        return;
    }
    self.can_show_duration -=displayLink.duration;
    if (self.can_show_duration<=0) {
        NSMutableDictionary *dic = (NSMutableDictionary *)[self.images objectAtIndex:_now_index];
        if (CFArrayGetCount(_pixelBuffs) > _now_index) {
            _target = (CVPixelBufferRef)CFArrayGetValueAtIndex(_pixelBuffs, _now_index);
        }else {
            _target = [self CVPixelBufferRefFromUiImage:[dic objectForKey:@"image"]];
            CFArrayAppendValue(_pixelBuffs, _target);
            [dic removeObjectForKey:@"image"];
        }
        
        self.updateBlock();
        
        _now_index += 1;
        if (_now_index >= self.images.count) {
            _now_index = 0;
        }
        self.can_show_duration = ((NSNumber*)[dic objectForKey:@"duration"]).floatValue;
    }
}

- (void)startGifDisplay {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updategif:)];
    if (@available(iOS 10.0, *)) {
        self.displayLink.preferredFramesPerSecond = 40;
    }
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)sd_GifImagesWithLocalData:(NSData *)data {
    if (!data) {
        return;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(source);
    UIImage *animatedImage;
    
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    } else {
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            if (!image) continue;
            
            UIImage *uiImage = [UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
            NSDictionary *dic = @{
                @"duration":@([self sd_frameDurationAtIndex:i source:source]),
                @"image":uiImage
            };
            [_images addObject:dic];
            CGImageRelease(image);
        }
    }
    CFRelease(source);
    [self startGifDisplay];
}

- (float)sd_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    }else {
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

- (void)sd_GIFImagesWithLocalNamed:(NSString *)name {
    if ([name hasSuffix:@".gif"]) {
        name = [name stringByReplacingCharactersInRange:NSMakeRange(name.length-4, 4) withString:@""];
    }
    CGFloat scale = [UIScreen mainScreen].scale;
    
    if (scale > 1.0f) {
        NSData *data = nil;
        if (scale>2.0f) {
            NSString *retinaPath = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@3x"] ofType:@"gif"];
            data = [NSData dataWithContentsOfFile:retinaPath];
        }
        if (!data){
            NSString *retinaPath = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@2x"] ofType:@"gif"];
            data = [NSData dataWithContentsOfFile:retinaPath];
        }
        
        if (!data) {
            NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
            data = [NSData dataWithContentsOfFile:path];
        }
        
        if (data) [self sd_GifImagesWithLocalData:data];
        
    }else {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data) [self sd_GifImagesWithLocalData:data];
    }
}

@end
