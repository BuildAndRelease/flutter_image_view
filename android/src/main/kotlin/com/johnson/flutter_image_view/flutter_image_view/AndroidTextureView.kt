package com.johnson.flutter_image_view.flutter_image_view

import android.content.Context
import android.graphics.*
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import android.view.Surface
import com.bumptech.glide.Glide
import com.bumptech.glide.integration.okhttp3.OkHttpUrlLoader
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.load.model.GlideUrl
import com.bumptech.glide.load.resource.gif.GifDrawable
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.transition.Transition
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import okhttp3.*
import okio.*
import java.io.IOException
import java.io.InputStream
import java.lang.ref.WeakReference


class AndroidTextureView(imageUrl : String, requestId : String, width : String, height : String, radius : String, context: Context, channel : MethodChannel, surfaceEntry : TextureRegistry.SurfaceTextureEntry) : Drawable.Callback {
    val imageUrl : String = imageUrl
    val requestId : String = requestId
    val width : Int = width.toInt()
    val height : Int = height.toInt()
    val radius : Int = radius.toInt()
    val canvasRect = Rect(0,0, width.toInt(),height.toInt())
    val radiusPath : Path = Path()
    val channel : WeakReference<MethodChannel> = WeakReference(channel);

    val context : WeakReference<Context> = WeakReference(context)
    var mOkHttpClient: OkHttpClient

    lateinit var drawable : Drawable
    val surfaceEntry : TextureRegistry.SurfaceTextureEntry = surfaceEntry
    var surface : Surface

    var target : CustomTarget<Drawable>
    var progressListener : ProgressListener

    var mainHandler: Handler = Handler(Looper.getMainLooper())


    init {
        val weakSelf = WeakReference<AndroidTextureView>(this)
        val rectF = RectF(0F,0F,this.width.toFloat(), this.height.toFloat())
        radiusPath.addRoundRect(rectF, this.radius.toFloat(), this.radius.toFloat(), Path.Direction.CW)
        this.surfaceEntry.surfaceTexture().setDefaultBufferSize(this.width, this.height)
        surface = Surface(this.surfaceEntry.surfaceTexture())

        progressListener = object : ProgressListener {
            override fun update(bytesRead: Long, contentLength: Long, done: Boolean) {
                val progress = (bytesRead.toFloat() / contentLength).toString()
                weakSelf.get()?.mainHandler?.post(object  : Runnable{
                    override fun run() {
                        weakSelf.get()?.channel?.get()?.invokeMethod("onProgress", mapOf("requestId" to requestId, "progress" to progress))
                    }
                })
            }
        }

        mOkHttpClient = OkHttpClient.Builder()
                .addNetworkInterceptor(object : Interceptor{
                    override fun intercept(chain: Interceptor.Chain): Response {
                        val originalResponse: Response = chain.proceed(chain.request())
                        return originalResponse.newBuilder()
                                .body(originalResponse.body()?.let { ProgressResponseBody(it, progressListener) })
                                .build()
                    }
                })
                .build()

        target = object : CustomTarget<Drawable>(this.width, this.height) {
            override fun onLoadFailed(errorDrawable: Drawable?) {
                weakSelf.get()?.mainHandler?.post(object  : Runnable{
                    override fun run() {
                        weakSelf.get()?.channel?.get()?.invokeMethod("onError", mapOf("requestId" to requestId, "progress" to "load failed"))
                    }
                })
                super.onLoadFailed(errorDrawable)
            }

            override fun onResourceReady(resource: Drawable, transition: Transition<in Drawable>?) {
                try {
                    weakSelf.get()?.drawable = resource
                    if (resource is GifDrawable) {
                        val canvas = weakSelf.get()?.surface?.lockCanvas(canvasRect)
                        weakSelf.get()?.radiusPath?.let { canvas?.clipPath(it) }
                        canvas?.let { resource.draw(it) }
                        weakSelf.get()?.surface?.unlockCanvasAndPost(canvas)
                        weakSelf.get()?.canvasRect?.let { resource.setBounds(it) }
                        resource.start()
                        resource.callback = this@AndroidTextureView
                    } else  {
                        val canvas = weakSelf.get()?.surface?.lockCanvas(weakSelf.get()?.canvasRect)
                        canvas?.save()
                        weakSelf.get()?.radiusPath?.let { canvas?.clipPath(it) }
                        resource?.bounds = canvasRect
                        if (canvas != null)
                            resource?.draw(canvas)
                        weakSelf.get()?.surface?.unlockCanvasAndPost(canvas)
                    }
                }catch (e : Exception) {
                    e.printStackTrace()
                }
                weakSelf.get()?.mainHandler?.post(object  : Runnable{
                    override fun run() {
                        weakSelf.get()?.channel?.get()?.invokeMethod("onDone", mapOf("requestId" to requestId))
                    }
                })
            }

            override fun onLoadCleared(placeholder: Drawable?) {

            }
        }

        Glide.get(context).registry.prepend(GlideUrl::class.java, InputStream::class.java, OkHttpUrlLoader.Factory(mOkHttpClient))
        Glide.with(context).asDrawable().load(this.imageUrl).skipMemoryCache(true).diskCacheStrategy(DiskCacheStrategy.NONE).into(target)
    }

    fun dispose() {
        context.get()?.let { Glide.with(it).clear(target) }
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
            canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
            who.draw(canvas)
            surface.unlockCanvasAndPost(canvas)
        }else {
            print("invalidateDrawable")
        }
    }

    override fun scheduleDrawable(who: Drawable, what: Runnable, `when`: Long) {
        print("scheduleDrawable")
    }

    private class ProgressResponseBody(private val responseBody: ResponseBody, private val progressListener: ProgressListener) : ResponseBody() {
        private var bufferedSource: BufferedSource? = null
        override fun contentType(): MediaType? {
            return responseBody.contentType()
        }

        @Throws(IOException::class)
        override fun contentLength(): Long {
            return responseBody.contentLength()
        }

        @Throws(IOException::class)
        override fun source(): BufferedSource {
            if (bufferedSource == null) {
                bufferedSource = Okio.buffer(source(responseBody.source()))
            }
            return bufferedSource!!
        }

        private fun source(source: Source): Source {
            return object : ForwardingSource(source) {
                var totalBytesRead = 0L

                @Throws(IOException::class)
                override fun read(sink: Buffer?, byteCount: Long): Long {
                    val bytesRead = super.read(sink, byteCount)
                    totalBytesRead += if (bytesRead != -1L) bytesRead else 0
                    progressListener.update(totalBytesRead, responseBody.contentLength(), bytesRead == -1L)
                    return bytesRead
                }
            }
        }
    }

    interface ProgressListener {
        fun update(bytesRead: Long, contentLength: Long, done: Boolean)
    }

}