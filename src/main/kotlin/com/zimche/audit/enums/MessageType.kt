package com.zimche.audit.enums

enum class MessageType(val displayName: String) {
    NOTIFICATION("Notification"),
    ALERT("Alert"),
    REMINDER("Reminder"),
    CHAT("Chat Message"),
    SYSTEM("System Message")
}
