package com.zimche.audit.entity

import com.zimche.audit.enums.UserRole
import jakarta.persistence.*
import org.hibernate.annotations.GenericGenerator
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime

@Entity
@Table(
    name = "users",
    indexes = [
        Index(name = "idx_user_email", columnList = "email", unique = true),
        Index(name = "idx_user_role", columnList = "role"),
        Index(name = "idx_user_university", columnList = "university_id"),
        Index(name = "idx_user_active", columnList = "is_active"),
        Index(name = "idx_user_created", columnList = "created_at")
    ]
)
@EntityListeners(AuditingEntityListener::class)
data class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(unique = true, nullable = false, length = 255)
    val email: String,

    @Column(nullable = false)
    val password: String,

    @Column(name = "first_name", nullable = false, length = 100)
    val firstName: String,

    @Column(name = "last_name", nullable = false, length = 100)
    val lastName: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    val role: UserRole,

    @Column(name = "phone_number", length = 20)
    val phoneNumber: String? = null,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @Column(name = "is_email_verified")
    val isEmailVerified: Boolean = false,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "university_id")
    val university: University? = null,

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @LastModifiedDate
    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    val fullName: String
        get() = "$firstName $lastName"

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as User
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()

    override fun toString(): String = "User(id=$id, email='$email', fullName='$fullName')"
}
