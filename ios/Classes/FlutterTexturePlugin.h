//
//  FlutterTexturePlugin.h
//  flutter_image_view
//
//  Created by johnson_zhong on 2021/8/21.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

typedef enum {
    UPDATETEXTURE = 0,
    ONPROGRESS = 1,
    ONERROR = 2,
    ONDONE = 3,
}TEXTURECALLBACKTYPE;

@interface FlutterTexturePlugin : NSObject <FlutterTexture>

- (instancetype)initWithImageStr:(NSString*)imageStr imageSize:(CGSize)size radius:(int)radius requestId:(NSString *)requestId callback:(void(^) (TEXTURECALLBACKTYPE, NSDictionary*)) callback;

- (void)dispose;

@end
