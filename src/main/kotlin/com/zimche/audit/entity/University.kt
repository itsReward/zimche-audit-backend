package com.zimche.audit.entity

import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(name = "universities")
@EntityListeners(AuditingEntityListener::class)
data class University(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false)
    val name: String,

    @Column(unique = true, nullable = false)
    val code: String,

    @Column(nullable = false)
    val address: String,

    @Column(name = "contact_email", nullable = false)
    val contactEmail: String,

    @Column(name = "contact_phone")
    val contactPhone: String? = null,

    @Column
    val website: String? = null,

    @Column(name = "established_year")
    val establishedYear: Int? = null,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @OneToMany(mappedBy = "university", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val users: MutableList<User> = mutableListOf(),

    @OneToMany(mappedBy = "university", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val documents: MutableList<Document> = mutableListOf(),

    @OneToMany(mappedBy = "university", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val audits: MutableList<Audit> = mutableListOf(),

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
        other as University
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "University(id=$id, name='$name', code='$code')"
}
