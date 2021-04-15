package com.taoweiji.flutter.flutter_platform_view

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class AndroidImageViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val androidImageView = AndroidImageView(context)
        androidImageView.viewId = viewId
        val params = args?.let { args as Map<*, *> }
        val imagePath = params?.get("imagePath") as String
        val imageData = params?.get("imageData") ?: ByteArray(0)
        val placeHolderPath = params?.get("placeHolderPath") ?: ""
        val placeHolderData = params?.get("placeHolderData") ?: ByteArray(0)
        val radius = (params?.get("radius") ?: 0f).toString().toFloat()
        androidImageView.imagePath = imagePath
        androidImageView.imageData = imageData as ByteArray
        androidImageView.placeholderPath = placeHolderPath as String
        androidImageView.placeholderData = placeHolderData as ByteArray
        androidImageView.radius = radius.toFloat()
        return androidImageView
    }
}