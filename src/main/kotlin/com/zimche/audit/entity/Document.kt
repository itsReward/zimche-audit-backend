package com.zimche.audit.entity

import com.zimche.audit.enums.DocumentStatus
import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "documents")
@EntityListeners(AuditingEntityListener::class)
data class Document(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false)
    val title: String,

    @Column(name = "file_name", nullable = false)
    val fileName: String,

    @Column(name = "file_url", nullable = false)
    val fileUrl: String,

    @Column(name = "file_size", nullable = false)
    val fileSize: Long,

    @Column(name = "content_type")
    val contentType: String? = null,

    @Column(columnDefinition = "TEXT")
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val status: DocumentStatus = DocumentStatus.PENDING,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "university_id", nullable = false)
    val university: University,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_by", nullable = false)
    val uploadedBy: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reviewed_by")
    val reviewedBy: User? = null,

    @Column(name = "reviewed_at")
    val reviewedAt: LocalDateTime? = null,

    @Column(name = "review_comments", columnDefinition = "TEXT")
    val reviewComments: String? = null,

    @OneToMany(mappedBy = "document", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val aiAnalyses: MutableList<AIAnalysis> = mutableListOf(),

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
        other as Document
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "Document(id=$id, title='$title', fileName='$fileName')"
}
