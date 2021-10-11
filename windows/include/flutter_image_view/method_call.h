#ifndef FLUTTER_PLUGIN_DESKTOP_WINDOW_PLUGIN_WINDOW_METHOD_CALL_
#define FLUTTER_PLUGIN_DESKTOP_WINDOW_PLUGIN_WINDOW_METHOD_CALL_

#include <windows.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

namespace DesktopWindowMethodCall
{
    class MethodCall
    {
    public:
        MethodCall(const flutter::MethodCall<flutter::EncodableValue> &Cmethod_call,
                   std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> Cresult);

        void loadTexture();
        void dispose();
        void cleanCache();
        void cachedPath();

    private:
        const flutter::MethodCall<flutter::EncodableValue> &method_call;
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result;
    };
}

#endif // FLUTTER_PLUGIN_DESKTOP_WINDOW_PLUGIN_WINDOW_METHOD_CALL_
