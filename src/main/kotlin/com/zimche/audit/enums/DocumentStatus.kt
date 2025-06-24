package com.zimche.audit.enums

enum class DocumentStatus(val displayName: String) {
    PENDING("Pending Review"),
    UNDER_REVIEW("Under Review"),
    APPROVED("Approved"),
    REJECTED("Rejected"),
    REQUIRES_REVISION("Requires Revision")
}
