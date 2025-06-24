package com.zimche.audit.entity

import com.zimche.audit.enums.AuditStatus
import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "audits")
@EntityListeners(AuditingEntityListener::class)
data class Audit(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false)
    val title: String,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: AuditStatus = AuditStatus.SCHEDULED,

    @Column(name = "scheduled_date", nullable = false)
    val scheduledDate: LocalDateTime,

    @Column(name = "start_date")
    val startDate: LocalDateTime? = null,

    @Column(name = "end_date")
    val endDate: LocalDateTime? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "university_id", nullable = false)
    val university: University,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to")
    val assignedTo: User? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by", nullable = false)
    val createdBy: User,

    @OneToMany(mappedBy = "audit", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val auditSteps: MutableList<AuditStep> = mutableListOf(),

    @Column(name = "final_report", columnDefinition = "TEXT")
    val finalReport: String? = null,

    @Column(name = "compliance_score")
    val complianceScore: Double? = null,

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @LastModifiedDate
    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as Audit
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "Audit(id=$id, title='$title', status=$status)"
}
