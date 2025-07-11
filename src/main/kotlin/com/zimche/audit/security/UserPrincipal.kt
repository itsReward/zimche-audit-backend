package com.zimche.audit.security

import com.zimche.audit.entity.User
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.userdetails.UserDetails

data class UserPrincipal(
    val id: Long,
    val email: String,
    private val password: String,
    val fullName: String,
    val universityId: Long?,
    private val authorities: Collection<GrantedAuthority>,
    val isActive: Boolean
) : UserDetails {

    override fun getAuthorities(): Collection<GrantedAuthority> = authorities

    override fun getPassword(): String = password

    override fun getUsername(): String = email

    override fun isAccountNonExpired(): Boolean = true

    override fun isAccountNonLocked(): Boolean = true

    override fun isCredentialsNonExpired(): Boolean = true

    override fun isEnabled(): Boolean = isActive

    companion object {
        fun create(user: User): UserPrincipal {
            val authorities = listOf(SimpleGrantedAuthority("ROLE_${user.role.name}"))
            
            return UserPrincipal(
                id = user.id,
                email = user.email,
                password = user.password,
                fullName = user.fullName,
                universityId = user.university?.id,
                authorities = authorities,
                isActive = user.isActive
            )
        }
    }
}
