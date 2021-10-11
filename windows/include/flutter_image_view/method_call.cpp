#include "method_call.h"
#include "../curl/curl.h"

namespace DesktopWindowMethodCall
{
    MethodCall::MethodCall(const flutter::MethodCall<flutter::EncodableValue> &Cmethod_call,
                           std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> Cresult): method_call(Cmethod_call)
    {
        result = std::move(Cresult);
    }

    void MethodCall::loadTexture()
    {
        
        /*const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        bool fullscreen = false;
        if (arguments)
        {
            auto fs_it = arguments->find(flutter::EncodableValue("fullscreen"));
            if (fs_it != arguments->end())
            {
                fullscreen = std::get<bool>(fs_it->second);
            }
        }
        HWND handle = GetActiveWindow();

        WINDOWPLACEMENT placement;

        GetWindowPlacement(handle, &placement);

        if (fullscreen)
        {
            placement.showCmd = SW_MAXIMIZE;
            SetWindowPlacement(handle, &placement);
        }
        else
        {
            placement.showCmd = SW_NORMAL;
            SetWindowPlacement(handle, &placement);
        }*/
    }

    void MethodCall::dispose() 
    {
        /*HWND handle = GetActiveWindow();

        WINDOWPLACEMENT placement;
        GetWindowPlacement(handle, &placement);

        result->Success(flutter::EncodableValue(placement.showCmd == SW_MAXIMIZE));*/
    }

    void MethodCall::cleanCache()
    {
        /*HWND handle = GetActiveWindow();

        WINDOWPLACEMENT placement;
        GetWindowPlacement(handle, &placement);

        if (placement.showCmd == SW_MAXIMIZE)
        {
            placement.showCmd = SW_NORMAL;
            SetWindowPlacement(handle, &placement);
        }
        else
        {
            placement.showCmd = SW_MAXIMIZE;
            SetWindowPlacement(handle, &placement);
        }
        result->Success(flutter::EncodableValue(true));*/
    }

    void MethodCall::cachedPath()
    {
        /*const auto *arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        bool border = false;
        if (arguments)
        {
            auto fs_it = arguments->find(flutter::EncodableValue("border"));
            if (fs_it != arguments->end())
            {
                border = std::get<bool>(fs_it->second);
            }
        }

        HWND hWnd = GetActiveWindow();

        result->Success(flutter::EncodableValue(true));*/
    }

}
