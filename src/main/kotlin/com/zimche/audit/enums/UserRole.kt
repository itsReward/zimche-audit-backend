package com.zimche.audit.enums

enum class UserRole(val displayName: String) {
    ADMIN("Administrator"),
    UNIVERSITY_STAFF("University Staff"),
    PEER_REVIEWER("Peer Reviewer"),
    SUPER_USER("Super User")
}
