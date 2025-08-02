package com.rentease.app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Optimize memory usage for image processing
        try {
            val activityManager = getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
            val memoryInfo = android.app.ActivityManager.MemoryInfo()
            activityManager.getMemoryInfo(memoryInfo)
            
            // Reduce image cache size if memory is low
            if (memoryInfo.lowMemory) {
                System.gc()
            }
        } catch (e: Exception) {
            // Ignore memory optimization errors
        }
    }
}
