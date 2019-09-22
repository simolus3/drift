#import "MoorFfiPlugin.h"
#import <moor_ffi/moor_ffi-Swift.h>

@implementation MoorFfiPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMoorFfiPlugin registerWithRegistrar:registrar];
}
@end
