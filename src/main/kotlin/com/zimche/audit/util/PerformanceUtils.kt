package com.zimche.audit.util

import org.slf4j.LoggerFactory

object PerformanceUtils {

    val logger = LoggerFactory.getLogger(PerformanceUtils::class.java)

    inline fun <T> measureTime(operation: String, block: () -> T): T {
        val startTime = System.currentTimeMillis()
        return try {
            block()
        } finally {
            val duration = System.currentTimeMillis() - startTime
            logger.debug("Operation '$operation' took ${duration}ms")
        }
    }

    inline fun <T> measureTimeWithResult(operation: String, block: () -> T): Pair<T, Long> {
        val startTime = System.currentTimeMillis()
        val result = block()
        val duration = System.currentTimeMillis() - startTime
        logger.debug("Operation '$operation' took ${duration}ms")
        return Pair(result, duration)
    }

    fun logMemoryUsage(operation: String) {
        val runtime = Runtime.getRuntime()
        val totalMemory = runtime.totalMemory()
        val freeMemory = runtime.freeMemory()
        val usedMemory = totalMemory - freeMemory
        val maxMemory = runtime.maxMemory()

        logger.debug(
            "Memory usage after '$operation': Used=${formatBytes(usedMemory)}, " +
            "Free=${formatBytes(freeMemory)}, Total=${formatBytes(totalMemory)}, " +
            "Max=${formatBytes(maxMemory)}"
        )
    }

    private fun formatBytes(bytes: Long): String {
        val mb = bytes / (1024 * 1024)
        return "${mb}MB"
    }

    class PerformanceTracker(private val operation: String) {
        private val startTime = System.currentTimeMillis()
        private var lastCheckpoint = startTime
        private val trackerLogger = LoggerFactory.getLogger("${PerformanceUtils::class.java.name}.Tracker")

        fun checkpoint(label: String) {
            val now = System.currentTimeMillis()
            val fromStart = now - startTime
            val fromLast = now - lastCheckpoint
            trackerLogger.debug("$operation - $label: +${fromLast}ms (total: ${fromStart}ms)")
            lastCheckpoint = now
        }

        fun finish(): Long {
            val duration = System.currentTimeMillis() - startTime
            trackerLogger.debug("$operation completed in ${duration}ms")
            return duration
        }
    }
}
