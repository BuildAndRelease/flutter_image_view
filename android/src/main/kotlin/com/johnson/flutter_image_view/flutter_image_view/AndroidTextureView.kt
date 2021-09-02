package com.johnson.flutter_image_view.flutter_image_view

import android.content.Context
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.Drawable
import android.view.Surface
import com.bumptech.glide.Glide
import com.bumptech.glide.load.resource.gif.GifDrawable
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.transition.Transition
import io.flutter.view.TextureRegistry

class AndroidTextureView(imageUrl : String, placeHolder : String,  errorHolder : String,width : String, height : String, radius : String, context: Context, surfaceEntry : TextureRegistry.SurfaceTextureEntry) : Drawable.Callback {
    val imageUrl : String = imageUrl
    val placeHolder : String = placeHolder
    val errorHolder : String = errorHolder
    val width : Int = width.toInt()
    val height : Int = height.toInt()
    val radius : Int = radius.toInt()
    val canvasRect = Rect(0,0, width.toInt(),height.toInt())
    val radiusPath : Path = Path()
    val context : Context = context

    var surface : Surface
    lateinit var drawable : Drawable
    val surfaceEntry : TextureRegistry.SurfaceTextureEntry = surfaceEntry

    var target : CustomTarget<Drawable>

    init {
        val rectF = RectF(0F,0F,this.width.toFloat(), this.height.toFloat())
        radiusPath.addRoundRect(rectF, this.radius.toFloat(), this.radius.toFloat(), Path.Direction.CW)
        this.surfaceEntry.surfaceTexture().setDefaultBufferSize(this.width, this.height)
        surface = Surface(this.surfaceEntry.surfaceTexture())
        target = object : CustomTarget<Drawable>(this.width, this.height) {
            override fun onLoadStarted(placeholder: Drawable?) {
                if (placeHolder != null){
                    val canvas = surface.lockCanvas(canvasRect)
                    canvas.save()
                    canvas.clipPath(radiusPath)
                    canvas.scale(width.toFloat() / (placeholder?.intrinsicWidth?.toFloat() ?: 1F), height.toFloat() / (placeholder?.intrinsicHeight?.toFloat() ?: 1F))
                    placeholder?.draw(canvas)
                    surface.unlockCanvasAndPost(canvas)
                }
                super.onLoadStarted(placeholder)
            }

            override fun onLoadFailed(errorDrawable: Drawable?) {
                if (errorDrawable != null) {
                    val canvas = surface.lockCanvas(canvasRect)
                    canvas.save()
                    canvas.clipPath(radiusPath)
                    canvas.scale(width.toFloat() / (errorDrawable?.intrinsicWidth?.toFloat() ?: 1F), height.toFloat() / (errorDrawable?.intrinsicHeight?.toFloat() ?: 1F))
                    errorDrawable?.draw(canvas)
                    surface.unlockCanvasAndPost(canvas)
                }
                super.onLoadFailed(errorDrawable)
            }

            override fun onResourceReady(resource: Drawable, transition: Transition<in Drawable>?) {
                try {
                    drawable = resource
                    if (resource is GifDrawable) {
                        val canvas = surface.lockCanvas(canvasRect)
                        canvas.clipPath(radiusPath)
                        resource.draw(canvas)
                        surface.unlockCanvasAndPost(canvas)
                        resource.setBounds(canvasRect)
                        resource.start()
                        resource.callback = this@AndroidTextureView
                    } else  {
                        val canvas = surface.lockCanvas(canvasRect)
                        canvas.save()
                        canvas.clipPath(radiusPath)
                        resource?.bounds = canvasRect
                        resource?.draw(canvas)
                        surface.unlockCanvasAndPost(canvas)
                    }
                }catch (e : Exception) {
                    e.printStackTrace()
                }
            }

            override fun onLoadCleared(placeholder: Drawable?) {

            }
        }
        Glide.with(context).asDrawable().load(this.imageUrl).placeholder(Drawable.createFromPath(this.placeHolder)).error(Drawable.createFromPath(this.errorHolder)).into(target)
    }

    fun dispose() {
        Glide.with(context).clear(target)
        (drawable as? GifDrawable)?.recycle()
        surface.release()
        surfaceEntry.release()
    }

    override fun unscheduleDrawable(who: Drawable, what: Runnable) {
        print("unscheduleDrawable")
    }

    override fun invalidateDrawable(who: Drawable) {
        if (surface.isValid) {
            val canvas = surface.lockCanvas(canvasRect)
            canvas.clipPath(radiusPath)
            who.draw(canvas)
            surface.unlockCanvasAndPost(canvas)
        }else {
            print("invalidateDrawable")
        }
    }

    override fun scheduleDrawable(who: Drawable, what: Runnable, `when`: Long) {
        print("scheduleDrawable")
    }

}