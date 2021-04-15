package com.taoweiji.flutter.flutter_platform_view

import android.content.Context
import android.view.View
import android.widget.ImageView
import com.bumptech.glide.Glide
import com.bumptech.glide.load.DecodeFormat
import com.bumptech.glide.load.resource.bitmap.RoundedCorners
import com.bumptech.glide.request.RequestOptions
import io.flutter.plugin.platform.PlatformView

class AndroidImageView(context: Context) : PlatformView {
    val context : Context = context;
    var viewId: Int = 0;
    var imagePath: String = "";
    var imageData: ByteArray = ByteArray(0);
    var placeholderPath: String = ""
    var placeholderData: ByteArray = ByteArray(0);
    var radius : Float = 0f
    override fun getView(): View {
        val imageView = ImageView(context)
        val options = RequestOptions().apply {
            centerInside()
            format(DecodeFormat.PREFER_RGB_565)
            RoundedCorners(radius.toInt())
        }
        Glide.with(context).load(imagePath).apply(options).into(imageView)
        return imageView
    }

    override fun dispose() {}
}