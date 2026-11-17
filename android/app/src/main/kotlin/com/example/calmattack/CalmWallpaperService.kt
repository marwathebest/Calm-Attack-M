package com.example.calmattack

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Calm Attack live wallpaper.
 *
 * A warm sunset background with softly drifting leaves and small flowers,
 * and the app's flower character in the middle, slowly opening and
 * closing in a 3-3-3 breathing rhythm (in 3 s, hold 3 s, out 3 s).
 * It only draws while the wallpaper is visible, to save battery.
 */
class CalmWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = CalmEngine()

    private inner class CalmEngine : Engine() {
        private val handler = Handler(Looper.getMainLooper())
        private val frameDelayMs = 1000L / 24 // Gentle motion, low battery use.
        private val startTime = SystemClock.elapsedRealtime()
        private var visible = false
        private var width = 0
        private var height = 0

        private val drawFrame = object : Runnable {
            override fun run() = draw()
        }

        // Colors from the app's "calm sunset" theme.
        private val cream = Color.rgb(0xFF, 0xF4, 0xEE)
        private val peach = Color.rgb(0xFF, 0xE3, 0xD3)
        private val rose = Color.rgb(0xC7, 0x69, 0x7A)
        private val coral = Color.rgb(0xE8, 0x90, 0x7A)
        private val softPeach = Color.rgb(0xF6, 0xB8, 0xA8)
        private val plum = Color.rgb(0x7A, 0x3E, 0x48)
        private val sun = Color.rgb(0xF7, 0xC5, 0x9F)
        private val glow = Color.rgb(0xFB, 0xD9, 0xC0)
        private val cheek = Color.rgb(0xEE, 0x9A, 0x8C)

        private val bgPaint = Paint()
        private val leafPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = withAlpha(coral, 0.18f)
        }
        private val stemPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = withAlpha(coral, 0.18f)
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
        }
        private val petalPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = withAlpha(rose, 0.14f)
        }
        private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
        private val ink = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            color = plum
        }
        private val path = Path()
        private val rect = RectF()

        override fun onVisibilityChanged(isVisible: Boolean) {
            visible = isVisible
            handler.removeCallbacks(drawFrame)
            if (isVisible) draw()
        }

        override fun onSurfaceChanged(holder: SurfaceHolder, format: Int, w: Int, h: Int) {
            super.onSurfaceChanged(holder, format, w, h)
            width = w
            height = h
            bgPaint.shader = LinearGradient(
                0f, 0f, 0f, h.toFloat(), cream, peach, Shader.TileMode.CLAMP,
            )
            draw()
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            super.onSurfaceDestroyed(holder)
            visible = false
            handler.removeCallbacks(drawFrame)
        }

        override fun onDestroy() {
            super.onDestroy()
            handler.removeCallbacks(drawFrame)
        }

        private fun draw() {
            val holder = surfaceHolder
            var canvas: Canvas? = null
            try {
                canvas = holder.lockCanvas()
                if (canvas != null) render(canvas)
            } finally {
                if (canvas != null) holder.unlockCanvasAndPost(canvas)
            }
            handler.removeCallbacks(drawFrame)
            if (visible) handler.postDelayed(drawFrame, frameDelayMs)
        }

        private fun render(canvas: Canvas) {
            val seconds = (SystemClock.elapsedRealtime() - startTime) / 1000f
            val density = resources.displayMetrics.density
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), bgPaint)
            drawPattern(canvas, seconds, density)
            drawBreathingFlower(canvas, seconds, density)
        }

        // ------------------------------------------------------------------
        // Drifting pattern

        private fun drawPattern(canvas: Canvas, seconds: Float, density: Float) {
            val tile = 92f * density
            stemPaint.strokeWidth = 1.6f * density

            // Drift slowly down and to the right, like petals in a breeze.
            val dy = seconds * 9f * density
            val dx = seconds * 4f * density
            val rowShift = floor(dy / tile).toInt()
            val colShift = floor(dx / tile).toInt()
            val fracY = dy - rowShift * tile
            val fracX = dx - colShift * tile

            val rows = (height / tile).toInt() + 3
            val cols = (width / tile).toInt() + 3
            for (i in -1 until rows) {
                val row = i - rowShift
                for (j in -1 until cols) {
                    val col = j - colShift
                    val stagger = if (row % 2 != 0) tile / 2 else 0f
                    val x = j * tile + fracX + stagger
                    val y = i * tile + fracY + tile / 2
                    // Fixed angle per tile plus a soft sway.
                    val base = (Math.floorMod(row * 7 + col * 13, 12)) * (PI / 6).toFloat()
                    val sway = 0.25f * sin(seconds * 0.7f + row * 0.9f + col * 1.3f)

                    canvas.save()
                    canvas.translate(x, y)
                    canvas.rotate(Math.toDegrees((base + sway).toDouble()).toFloat())
                    if (Math.floorMod(row + col, 2) == 0) {
                        drawSprig(canvas, density)
                    } else {
                        drawSmallFlower(canvas, density)
                    }
                    canvas.restore()
                }
            }
        }

        private fun drawSprig(canvas: Canvas, d: Float) {
            val length = 34f * d
            path.reset()
            path.moveTo(0f, length / 2)
            path.quadTo(6f * d, 0f, 0f, -length / 2)
            canvas.drawPath(path, stemPaint)
            for (i in 0 until 3) {
                val y = length / 2 - 8f * d - i * 9f * d
                val size = (9f - i * 1.5f) * d
                drawLeaf(canvas, 3f * d, y, -45f, size, leafPaint)
                drawLeaf(canvas, 3f * d, y, -135f, size, leafPaint)
            }
            drawLeaf(canvas, 0f, -length / 2, -90f, 7f * d, leafPaint)
        }

        private fun drawLeaf(canvas: Canvas, x: Float, y: Float, degrees: Float, length: Float, paint: Paint) {
            canvas.save()
            canvas.translate(x, y)
            canvas.rotate(degrees)
            path.reset()
            path.moveTo(0f, 0f)
            path.quadTo(length * 0.5f, -length * 0.42f, length, 0f)
            path.quadTo(length * 0.5f, length * 0.42f, 0f, 0f)
            canvas.drawPath(path, paint)
            canvas.restore()
        }

        private fun drawSmallFlower(canvas: Canvas, d: Float) {
            for (i in 0 until 5) {
                canvas.save()
                canvas.rotate(i * 72f)
                rect.set(-4f * d, -12f * d, 4f * d, -1f * d)
                canvas.drawOval(rect, petalPaint)
                canvas.restore()
            }
            fill.color = withAlpha(rose, 0.25f)
            canvas.drawCircle(0f, 0f, 3.2f * d, fill)
        }

        // ------------------------------------------------------------------
        // Breathing flower in the middle

        /** 0 = closed, 1 = open, following 3 s in, 3 s hold, 3 s out. */
        private fun bloomAt(seconds: Float): Float {
            val t = seconds % 9f
            val ease = { x: Float -> (1 - cos(x * PI.toFloat())) / 2 }
            return when {
                t < 3f -> ease(t / 3f)
                t < 6f -> 1f
                else -> 1f - ease((t - 6f) / 3f)
            }
        }

        private fun drawBreathingFlower(canvas: Canvas, seconds: Float, d: Float) {
            val bloom = bloomAt(seconds)
            val holding = (seconds % 9f) in 3f..6f
            val r = min(width, height) * 0.24f
            val cx = width / 2f
            val cy = height * 0.42f

            fill.color = withAlpha(glow, 0.35f + 0.25f * bloom)
            canvas.drawCircle(cx, cy, r * (0.55f + 0.4f * bloom), fill)

            drawPetalRing(canvas, cx, cy, 8, r * (0.42f + 0.40f * bloom), r * (0.20f + 0.14f * bloom),
                0.25f + 0.75f * bloom, -PI.toFloat() / 2 + bloom * PI.toFloat() / 16, rose)
            drawPetalRing(canvas, cx, cy, 8, r * (0.34f + 0.26f * bloom), r * (0.16f + 0.10f * bloom),
                0.2f + 0.8f * bloom, -PI.toFloat() / 2 + PI.toFloat() / 8 - bloom * PI.toFloat() / 16, softPeach)

            val centerR = r * (0.22f + 0.04f * bloom)
            fill.color = sun
            canvas.drawCircle(cx, cy, centerR, fill)
            drawFace(canvas, cx, cy, centerR, holding, bloom)
        }

        private fun drawPetalRing(
            canvas: Canvas, cx: Float, cy: Float, count: Int, length: Float, width: Float,
            spread: Float, rotation: Float, color: Int,
        ) {
            fill.color = color
            for (i in 0 until count) {
                val even = rotation + i * 2 * PI.toFloat() / count
                var fromUp = (even + PI.toFloat() / 2) % (2 * PI.toFloat())
                if (fromUp < 0) fromUp += 2 * PI.toFloat()
                if (fromUp > PI) fromUp -= 2 * PI.toFloat()
                val angle = -PI.toFloat() / 2 + fromUp * spread

                canvas.save()
                canvas.translate(cx, cy)
                canvas.rotate(Math.toDegrees(angle.toDouble()).toFloat() - 90f)
                path.reset()
                path.moveTo(0f, 0f)
                path.cubicTo(width, length * 0.25f, width * 0.8f, length * 0.85f, 0f, length)
                path.cubicTo(-width * 0.8f, length * 0.85f, -width, length * 0.25f, 0f, 0f)
                canvas.drawPath(path, fill)
                canvas.restore()
            }
        }

        private fun drawFace(canvas: Canvas, cx: Float, cy: Float, radius: Float, holding: Boolean, bloom: Float) {
            ink.strokeWidth = radius * 0.09f
            val eyeY = cy - radius * 0.12f
            val eyeX = radius * 0.38f
            if (holding) {
                fill.color = plum
                canvas.drawCircle(cx - eyeX, eyeY, radius * 0.09f, fill)
                canvas.drawCircle(cx + eyeX, eyeY, radius * 0.09f, fill)
            } else {
                for (dx in floatArrayOf(-eyeX, eyeX)) {
                    rect.set(cx + dx - radius * 0.14f, eyeY - radius * 0.14f, cx + dx + radius * 0.14f, eyeY + radius * 0.14f)
                    canvas.drawArc(rect, 0f, 180f, false, ink)
                }
            }
            fill.color = withAlpha(cheek, 0.7f)
            for (dx in floatArrayOf(-radius * 0.58f, radius * 0.58f)) {
                rect.set(cx + dx - radius * 0.17f, cy + radius * 0.1f, cx + dx + radius * 0.17f, cy + radius * 0.3f)
                canvas.drawOval(rect, fill)
            }
            val my = cy + radius * 0.3f
            if (!holding && bloom > 0.001f && bloom < 0.999f) {
                rect.set(cx - radius * 0.09f, my - radius * 0.12f, cx + radius * 0.09f, my + radius * 0.12f)
                canvas.drawOval(rect, ink)
            } else {
                rect.set(cx - radius * 0.16f, my - radius * 0.26f, cx + radius * 0.16f, my + radius * 0.06f)
                canvas.drawArc(rect, 11f, 158f, false, ink)
            }
        }

        private fun withAlpha(color: Int, alpha: Float): Int =
            Color.argb((max(0f, min(1f, alpha)) * 255).toInt(), Color.red(color), Color.green(color), Color.blue(color))
    }
}
