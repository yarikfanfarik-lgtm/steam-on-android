package com.steamonandroid

import android.app.Activity
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView

class GameActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
        val root = FrameLayout(this).apply { setBackgroundColor(Color.BLACK) }
        val hint = TextView(this).apply {
            text = "Игровой экран / runtime"
            setTextColor(Color.WHITE); textSize = 18f; alpha = .7f
            gravity = Gravity.CENTER
        }
        root.addView(hint, FrameLayout.LayoutParams(-1, -1))
        val prefs = getSharedPreferences("settings", MODE_PRIVATE)
        val size = 46 + prefs.getInt("size", 55) / 3
        val alpha = prefs.getInt("alpha", 65) / 100f
        val keys = listOf("W", "A", "S", "D", "SPACE", "SHIFT", "CTRL", "E", "ESC")
        keys.forEachIndexed { i, key ->
            if (!prefs.getBoolean("key_$key", true) && key != "W") return@forEachIndexed
            val v = control(key, size, alpha)
            val lp = FrameLayout.LayoutParams(if (key == "SPACE") size * 3 else size, size)
            lp.leftMargin = 24 + (i % 4) * (size + 10)
            lp.topMargin = 40 + (i / 4) * (size + 10)
            root.addView(v, lp)
            makeDraggable(v)
        }
        addMouse(root, "ЛКМ", 1, size, alpha, Gravity.RIGHT or Gravity.CENTER_VERTICAL, 24)
        addMouse(root, "ПКМ", 2, size, alpha, Gravity.RIGHT or Gravity.CENTER_VERTICAL, 110)
        setContentView(root)
    }

    private fun control(text: String, size: Int, alpha: Float) = TextView(this).apply {
        this.text = text; textSize = 12f; gravity = Gravity.CENTER
        setTextColor(Color.WHITE); this.alpha = alpha
        background = rounded()
        setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_DOWN || event.action == MotionEvent.ACTION_MOVE || event.action == MotionEvent.ACTION_UP) performClick()
            false
        }
    }

    private fun addMouse(root: FrameLayout, text: String, id: Int, size: Int, alpha: Float, gravity: Int, margin: Int) {
        val v = control(text, size + 10, alpha)
        val lp = FrameLayout.LayoutParams(size + 10, size + 10).apply { this.gravity = gravity; rightMargin = 18; topMargin = margin }
        root.addView(v, lp)
        makeDraggable(v)
    }

    private fun rounded() = GradientDrawable().apply {
        cornerRadius = 18f; setColor(0x661B1D22); setStroke(2, 0x88FFFFFF.toInt())
    }

    private fun makeDraggable(view: View) {
        var dx = 0f; var dy = 0f
        view.setOnTouchListener { v, e ->
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> { dx = v.x - e.rawX; dy = v.y - e.rawY; true }
                MotionEvent.ACTION_MOVE -> { v.x = e.rawX + dx; v.y = e.rawY + dy; true }
                else -> false
            }
        }
    }
}
