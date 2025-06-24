package com.zimche.audit.dto.response

data class DashboardStatsResponse(
    val totalUsers: Long,
    val activeUsers: Long,
    val totalUniversities: Long,
    val activeUniversities: Long,
    val totalDocuments: Long,
    val pendingDocuments: Long,
    val totalAudits: Long,
    val activeAudits: Long,
    val unreadMessages: Long,
    val recentActivity: List<ActivityResponse>
)

data class ActivityResponse(
    val id: Long,
    val type: String, // "DOCUMENT_UPLOADED", "AUDIT_CREATED", "MESSAGE_SENT", etc.
    val description: String,
    val entityId: Long?,
    val entityType: String?, // "DOCUMENT", "AUDIT", "MESSAGE", etc.
    val userId: Long,
    val userName: String,
    val timestamp: java.time.LocalDateTime
)
