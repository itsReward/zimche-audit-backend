package com.zimche.audit.util

import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

object DateUtils {

    val DEFAULT_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")
    val DATE_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    val TIME_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("HH:mm:ss")
    val DISPLAY_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("MMM dd, yyyy 'at' HH:mm")

    fun formatDateTime(dateTime: LocalDateTime): String {
        return dateTime.format(DEFAULT_FORMATTER)
    }

    fun formatDate(dateTime: LocalDateTime): String {
        return dateTime.format(DATE_FORMATTER)
    }

    fun formatTime(dateTime: LocalDateTime): String {
        return dateTime.format(TIME_FORMATTER)
    }

    fun formatForDisplay(dateTime: LocalDateTime): String {
        return dateTime.format(DISPLAY_FORMATTER)
    }

    fun getTimeAgo(dateTime: LocalDateTime): String {
        val now = LocalDateTime.now()
        val minutes = ChronoUnit.MINUTES.between(dateTime, now)
        val hours = ChronoUnit.HOURS.between(dateTime, now)
        val days = ChronoUnit.DAYS.between(dateTime, now)

        return when {
            minutes < 1 -> "Just now"
            minutes < 60 -> "$minutes minute${if (minutes != 1L) "s" else ""} ago"
            hours < 24 -> "$hours hour${if (hours != 1L) "s" else ""} ago"
            days < 7 -> "$days day${if (days != 1L) "s" else ""} ago"
            days < 30 -> "${days / 7} week${if (days / 7 != 1L) "s" else ""} ago"
            days < 365 -> "${days / 30} month${if (days / 30 != 1L) "s" else ""} ago"
            else -> "${days / 365} year${if (days / 365 != 1L) "s" else ""} ago"
        }
    }

    fun isToday(dateTime: LocalDateTime): Boolean {
        val today = LocalDateTime.now()
        return dateTime.toLocalDate() == today.toLocalDate()
    }

    fun isThisWeek(dateTime: LocalDateTime): Boolean {
        val now = LocalDateTime.now()
        val weekStart = now.minusDays(now.dayOfWeek.value - 1L)
        val weekEnd = weekStart.plusDays(6)
        return dateTime.isAfter(weekStart) && dateTime.isBefore(weekEnd)
    }

    fun isThisMonth(dateTime: LocalDateTime): Boolean {
        val now = LocalDateTime.now()
        return dateTime.year == now.year && dateTime.month == now.month
    }

    fun addBusinessDays(startDate: LocalDateTime, businessDays: Int): LocalDateTime {
        var result = startDate
        var daysToAdd = businessDays

        while (daysToAdd > 0) {
            result = result.plusDays(1)
            // Skip weekends (Saturday = 6, Sunday = 7)
            if (result.dayOfWeek.value < 6) {
                daysToAdd--
            }
        }

        return result
    }

    fun getStartOfDay(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.withHour(0).withMinute(0).withSecond(0).withNano(0)
    }

    fun getEndOfDay(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.withHour(23).withMinute(59).withSecond(59).withNano(999999999)
    }

    fun getStartOfWeek(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.minusDays(dateTime.dayOfWeek.value - 1L)
            .withHour(0).withMinute(0).withSecond(0).withNano(0)
    }

    fun getEndOfWeek(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.plusDays(7L - dateTime.dayOfWeek.value)
            .withHour(23).withMinute(59).withSecond(59).withNano(999999999)
    }

    fun getStartOfMonth(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.withDayOfMonth(1)
            .withHour(0).withMinute(0).withSecond(0).withNano(0)
    }

    fun getEndOfMonth(dateTime: LocalDateTime): LocalDateTime {
        return dateTime.withDayOfMonth(dateTime.toLocalDate().lengthOfMonth())
            .withHour(23).withMinute(59).withSecond(59).withNano(999999999)
    }

    fun calculateBusinessDays(startDate: LocalDateTime, endDate: LocalDateTime): Int {
        var start = startDate.toLocalDate()
        val end = endDate.toLocalDate()
        var businessDays = 0

        while (!start.isAfter(end)) {
            // Skip weekends
            if (start.dayOfWeek.value < 6) {
                businessDays++
            }
            start = start.plusDays(1)
        }

        return businessDays
    }
}
