//
//  FlutterTexturePlugin.h
//  flutter_image_view
//
//  Created by johnson_zhong on 2021/8/21.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface FlutterTexturePlugin : NSObject <FlutterTexture>

- (instancetype)initWithImageStr:(NSString*)imageStr imageSize:(CGSize)size radius:(int)radius callback:(void(^) (void)) callback;

- (void)dispose;

@end
