package com.erkanoz.golge

import android.graphics.Rect
import android.os.Build
import android.view.View
import android.view.ViewGroup
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // Dokunmatik kontrol kaydırmayla çalışır: ekranın kenarından başlayan bir
    // kaydırmayı Android "geri" sanıp oyunu kapatmasın. Sistem her kenarda en
    // çok 200dp yüksekliğe izin verir; başparmakların olduğu alt kısım korunur.
    private val exclusion = View.OnLayoutChangeListener { v, _, _, _, _, _, _, _, _ ->
        applyExclusion(v)
        noFocusHighlight(v)
    }

    override fun onPostResume() {
        super.onPostResume()
        // Klavye bağlı tablette oyun alanı odaklanınca Android etrafına yeşil
        // bir odak çerçevesi çiziyordu: kapatılır.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            noFocusHighlight(window.decorView)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val root = window.decorView
            root.removeOnLayoutChangeListener(exclusion)
            root.addOnLayoutChangeListener(exclusion)
            applyExclusion(root)
        }
    }

    private fun noFocusHighlight(v: View) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        v.defaultFocusHighlightEnabled = false
        if (v is ViewGroup) {
            for (i in 0 until v.childCount) noFocusHighlight(v.getChildAt(i))
        }
    }

    private fun applyExclusion(v: View) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val h = v.height
        val w = v.width
        if (h <= 0 || w <= 0) return
        val band = (200 * resources.displayMetrics.density).toInt()
        val edge = (48 * resources.displayMetrics.density).toInt()
        v.systemGestureExclusionRects = listOf(
            Rect(0, h - band, edge, h),
            Rect(w - edge, h - band, w, h),
        )
    }
}
