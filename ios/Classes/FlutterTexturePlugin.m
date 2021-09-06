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

@interface FlutterTexturePlugin()


@property (nonatomic) CVPixelBufferRef target;

@property (nonatomic, assign) CGSize imageSize;//图片实际大小 px
@property (nonatomic, assign) CGSize screenSize;//图片实际大小 px
@property (nonatomic, copy) void(^updateBlock) (TEXTURECALLBACKTYPE, NSDictionary*);
@property (nonatomic, copy) NSString * requestId;

//下方是展示gif图相关的
@property (nonatomic, strong) CADisplayLink * displayLink;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) SDWebImageDownloadToken *currentToken;
@property (nonatomic, assign) CGFloat frameDuration;//帧率
@property (nonatomic, assign) int now_index;//当前展示的第几帧
@property (nonatomic, assign) int radius;//当前展示的圆角
@property (nonatomic, assign) CGFloat can_show_duration;//下一帧要展示的时间差

@end



@implementation FlutterTexturePlugin

- (instancetype)initWithImageStr:(NSString*)imageStr imageSize:(CGSize)size radius:(int)radius requestId:(NSString *)requestId callback:(void(^) (TEXTURECALLBACKTYPE, NSDictionary*)) callback{
    self = [super init];
    if (self){
        _updateBlock = callback;
        _requestId = requestId;
        self.screenSize = [[UIScreen mainScreen] bounds].size;
        self.radius = radius;
        if (size.width != 0 && size.height != 0) self.imageSize = size;
        if ([imageStr hasPrefix:@"http://"]||[imageStr hasPrefix:@"https://"]) {
            [self loadImageWithStrFromWeb:imageStr];
        } else {
            [self loadImageWithStrForLocal:imageStr];
        }
    }
    return self;
}

- (CVPixelBufferRef)copyPixelBuffer {
    if ([_image images]) {
        CVPixelBufferRelease(_target);
        _target = [self CVPixelBufferRefFromUiImage:[[_image images] objectAtIndex:_now_index]];
        return CVPixelBufferRetain(_target);
    }else if (_target) {
        return CVPixelBufferRetain(_target);
    }else {
        return  nil;
    }
}

-(void)dispose{
    self.displayLink.paused = YES;
    [self.displayLink invalidate];
    self.displayLink = nil;
    if (_currentToken) [_currentToken cancel];
    if (_target) CVPixelBufferRelease(_target);
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
    __weak typeof(FlutterTexturePlugin*) weakSelf = self;
    [[SDImageCache sharedImageCache] diskImageDataQueryForKey:imageStr completion:^(NSData * _Nullable data) {
        if (data) {
            [weakSelf loadImage:[UIImage sd_imageWithGIFData:data]];
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
    UIImage *image = [UIImage imageNamed:imageStr];
    if (image) {
        [self loadImage:image];
        return;
    }
    image = [UIImage imageWithContentsOfFile:imageStr];
    if (image) {
        [self loadImage:image];
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
    if (image.images.count > 1) {
        _frameDuration = image.duration*1.0/image.images.count;
        _image = image;
        [self startGifDisplay];
    } else {
        _target = [self CVPixelBufferRefFromUiImage:image];
        if (_updateBlock) _updateBlock(UPDATETEXTURE, @{});
    }
}

- (void)startGifDisplay {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updategif:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)updategif:(CADisplayLink*)displayLink{
    self.can_show_duration -=displayLink.duration;
    if (self.can_show_duration<=0) {
        _now_index += 1;
        if (_now_index >= [[_image images] count]) _now_index = 0;
        self.can_show_duration = _frameDuration;
        self.updateBlock(UPDATETEXTURE, @{});
    }
}

@end
