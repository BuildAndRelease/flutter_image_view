#import "FlutterImageViewPlugin.h"
#if __has_include(<flutter_image_view/flutter_image_view-Swift.h>)
#import <flutter_image_view/flutter_image_view-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_image_view-Swift.h"
#endif

@implementation FlutterImageViewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterImageViewPlugin registerWithRegistrar:registrar];
}
@end
