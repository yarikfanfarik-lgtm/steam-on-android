package com.steamonandroid

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.*
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread

class MainActivity : Activity() {
    private lateinit var status: TextView
    private lateinit var progress: ProgressBar
    private val prefs by lazy { getSharedPreferences("settings", MODE_PRIVATE) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        buildUi()
    }

    private fun buildUi() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(28, 22, 28, 22)
            setBackgroundColor(0xFF101114.toInt())
        }
        val title = TextView(this).apply { text = "Steam on Android"; textSize = 28f; setTextColor(0xFFFFFFFF.toInt()) }
        val subtitle = TextView(this).apply {
            text = "Локальный запуск Windows-игр через совместимый runtime"
            textSize = 14f; setTextColor(0xFFB8BBC4.toInt()); setPadding(0, 4, 0, 18)
        }
        root.addView(title); root.addView(subtitle)

        status = TextView(this).apply { text = "Runtime: не установлен"; textSize = 16f; setTextColor(0xFFE6E7EA.toInt()) }
        root.addView(status)

        val login = button("Войти в Steam") { openUrl("https://store.steampowered.com/login/") }
        root.addView(login)
        root.addView(button("Скачать SteamSetup.exe") { downloadSteam() })
        root.addView(button("Запустить Steam / игру") { showRuntimeInfo() })
        root.addView(button("Настроить экранные кнопки") { openControls() })

        progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply { visibility = View.GONE; max = 100 }
        root.addView(progress, LinearLayout.LayoutParams(-1, 12))
        root.addView(Space(this), LinearLayout.LayoutParams(1, 0, 1f))
        root.addView(TextView(this).apply {
            text = "Важно: Steam и Windows-игры требуют совместимый ARM/x86 runtime (Wine/Box64). Приложение не содержит проприетарные файлы Steam."
            textSize = 12f; setTextColor(0xFF8F929B.toInt())
        })
        setContentView(root)
    }

    private fun button(text: String, action: () -> Unit) = Button(this).apply {
        this.text = text; setOnClickListener { action() }
        isAllCaps = false
    }

    private fun openUrl(url: String) {
        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    }

    private fun downloadSteam() {
        progress.visibility = View.VISIBLE
        status.text = "Скачивание SteamSetup.exe..."
        thread {
            try {
                val url = URL("https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe")
                val conn = url.openConnection() as HttpURLConnection
                conn.connectTimeout = 15000; conn.readTimeout = 30000
                conn.connect()
                val total = conn.contentLengthLong
                val dir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)!!
                val file = File(dir, "SteamSetup.exe")
                conn.inputStream.use { input -> file.outputStream().use { out ->
                    val buf = ByteArray(8192); var done = 0L; var n: Int
                    while (input.read(buf).also { n = it } > 0) {
                        out.write(buf, 0, n); done += n
                        if (total > 0) runOnUiThread { progress.progress = ((done * 100) / total).toInt() }
                    }
                }}
                runOnUiThread { progress.visibility = View.GONE; status.text = "SteamSetup сохранён: ${file.name}" }
            } catch (e: Exception) {
                runOnUiThread { progress.visibility = View.GONE; status.text = "Ошибка загрузки: ${e.message}" }
            }
        }
    }

    private fun showRuntimeInfo() {
        AlertDialogBuilder().setTitle("Runtime")
            .setMessage("Для настоящего запуска Windows-игр на телефоне нужен Wine + Box64/Box86 или аналогичный runtime. В этой версии UI и управление готовы, а runtime нужно подключить отдельно.")
            .setPositiveButton("ОК", null).show()
    }

    private fun openControls() {
        val editor = ControlEditor(this, prefs)
        editor.show()
    }

    private fun AlertDialogBuilder() = android.app.AlertDialog.Builder(this)
}

private class ControlEditor(private val activity: Activity, private val prefs: android.content.SharedPreferences) {
    fun show() {
        val box = LinearLayout(activity).apply { orientation = LinearLayout.VERTICAL; setPadding(32, 10, 32, 10) }
        val size = SeekBar(activity).apply { max = 100; progress = prefs.getInt("size", 55) }
        val alpha = SeekBar(activity).apply { max = 100; progress = prefs.getInt("alpha", 65) }
        box.addView(label("Размер кнопок")); box.addView(size)
        box.addView(label("Прозрачность")); box.addView(alpha)
        val checks = arrayOf("WASD", "Space", "Shift", "Ctrl", "E", "Esc", "ЛКМ", "ПКМ")
        checks.forEach { key ->
            val cb = CheckBox(activity).apply { text = key; isChecked = prefs.getBoolean("key_$key", true) }
            box.addView(cb)
            cb.setOnCheckedChangeListener { _, value -> prefs.edit().putBoolean("key_$key", value).apply() }
        }
        android.app.AlertDialog.Builder(activity).setTitle("Экранное управление")
            .setMessage("В боевом режиме элементы можно будет перетаскивать по экрану; параметры сохраняются локально.")
            .setView(box).setPositiveButton("Сохранить") { _, _ ->
                prefs.edit().putInt("size", size.progress).putInt("alpha", alpha.progress).apply()
            }.setNegativeButton("Отмена", null).show()
    }
    private fun label(s: String) = TextView(activity).apply { text = s; textSize = 14f }
}
