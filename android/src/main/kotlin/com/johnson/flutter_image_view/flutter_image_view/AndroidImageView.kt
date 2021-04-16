package com.taoweiji.flutter.flutter_platform_view

import android.content.Context
import android.view.View
import android.widget.ImageView
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.load.resource.bitmap.RoundedCorners
import com.bumptech.glide.load.resource.drawable.DrawableTransitionOptions
import com.bumptech.glide.request.RequestOptions
import io.flutter.plugin.platform.PlatformView

class AndroidImageView(context: Context) : PlatformView {
    val context : Context = context;
    var viewId: Int = 0;
    var imagePath: String = "";
    var imageData: ByteArray = ByteArray(0);
    var placeholderPath: String = ""
    var placeholderData: ByteArray = ByteArray(0);
    var radius : Int = 0
    override fun getView(): View {
        val imageView = ImageView(context)
        imageView.scaleType = ImageView.ScaleType.FIT_XY
        if (radius > 0) {
            Glide.with(context).load(imagePath).apply(RequestOptions.bitmapTransform(RoundedCorners(radius))).diskCacheStrategy(DiskCacheStrategy.ALL).transition(DrawableTransitionOptions.withCrossFade(300)).into(imageView)
        }else {
            Glide.with(context).load(imagePath).diskCacheStrategy(DiskCacheStrategy.ALL).transition(DrawableTransitionOptions.withCrossFade(300)).into(imageView)
        }
        return imageView
    }

    override fun dispose() {}
}
