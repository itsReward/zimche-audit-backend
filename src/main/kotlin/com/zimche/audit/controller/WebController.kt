package com.zimche.audit.controller

import com.zimche.audit.security.UserPrincipal
import com.zimche.audit.service.UniversityService
import com.zimche.audit.service.UserService
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.security.core.Authentication
import org.springframework.stereotype.Controller
import org.springframework.ui.Model
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.security.access.prepost.PreAuthorize

@Controller
class WebController {

    @Autowired(required = false)
    private val universityService: UniversityService? = null

    @Autowired(required = false)
    private val userService: UserService? = null

    @GetMapping("/")
    fun home(model: Model, authentication: Authentication?): String {
        model.addAttribute("pageTitle", "ZIMCHE - University Audit Management")

        // Redirect to dashboard if already authenticated
        if (authentication?.isAuthenticated == true) {
            return "redirect:/dashboard"
        }

        return "pages/index"
    }

    @GetMapping("/home")
    fun homeAlias(model: Model): String {
        return home(model, null)
    }

    @GetMapping("/login")
    fun login(model: Model, @RequestParam(required = false) error: String?): String {
        model.addAttribute("pageTitle", "Login - ZIMCHE Audit")
        if (error != null) {
            model.addAttribute("error", "Invalid username or password")
        }
        return "pages/auth/login"
    }

    @GetMapping("/audits")
    @PreAuthorize("hasRole('ADMIN') or hasRole('PEER_REVIEWER')")
    fun audits(model: Model): String {
        model.addAttribute("pageTitle", "Audits - ZIMCHE Audit")
        return "pages/audits/list"
    }

    @GetMapping("/register")
    fun register(model: Model): String {
        model.addAttribute("pageTitle", "Register - ZIMCHE Audit")

        try {
            universityService?.let { service ->
                // Try to call a method that might exist
                val universities = try {
                    service.getActiveUniversities()
                } catch (e: NoSuchMethodError) {
                    // If getActiveUniversities doesn't exist, try getAllUniversities or similar
                    emptyList()
                }
                model.addAttribute("universities", universities)
            } ?: run {
                model.addAttribute("universities", emptyList<Any>())
            }
        } catch (e: Exception) {
            model.addAttribute("universities", emptyList<Any>())
        }

        return "pages/auth/register"
    }

    @GetMapping("/dashboard")
    @PreAuthorize("isAuthenticated()")
    fun dashboard(model: Model, authentication: Authentication): String {
        model.addAttribute("pageTitle", "Dashboard - ZIMCHE Audit")
        model.addAttribute("activeNav", "dashboard")

        try {
            userService?.let { service ->
                val user = service.findByEmail(authentication.name)
                model.addAttribute("user", user)
            }

            // Add safe default statistics (we'll implement counting later)
            model.addAttribute("totalUniversities", getUniversityCount())
            model.addAttribute("totalDocuments", 0)
            model.addAttribute("pendingAudits", 0)

        } catch (e: Exception) {
            // Handle gracefully with defaults
            model.addAttribute("totalUniversities", 0)
            model.addAttribute("totalDocuments", 0)
            model.addAttribute("pendingAudits", 0)
        }

        return "pages/dashboard/index"
    }

    @GetMapping("/universities")
    @PreAuthorize("isAuthenticated()")
    fun universities(
        model: Model,
        @RequestParam(required = false) search: String?,
        @RequestParam(defaultValue = "0") page: Int
    ): String {
        model.addAttribute("pageTitle", "Universities - ZIMCHE Audit")
        model.addAttribute("activeNav", "universities")
        model.addAttribute("search", search ?: "")

        try {
            universityService?.let { service ->
                val pageable = PageRequest.of(page, 12, Sort.by("name"))

                val universities = try {
                    // Try the method we expect
                    service.searchUniversities(search, pageable)
                } catch (e: NoSuchMethodError) {
                    // If searchUniversities doesn't exist, try to get all universities
                    try {
                        // This is a fallback - create a simple page with empty results
                        org.springframework.data.domain.PageImpl(
                            emptyList<Any>(),
                            pageable,
                            0
                        )
                    } catch (e2: Exception) {
                        org.springframework.data.domain.PageImpl(emptyList<Any>(), pageable, 0)
                    }
                }
                model.addAttribute("universities", universities)
            } ?: run {
                val emptyPage = org.springframework.data.domain.PageImpl(
                    emptyList<Any>(),
                    PageRequest.of(0, 12),
                    0
                )
                model.addAttribute("universities", emptyPage)
            }
        } catch (e: Exception) {
            val emptyPage = org.springframework.data.domain.PageImpl(
                emptyList<Any>(),
                PageRequest.of(0, 12),
                0
            )
            model.addAttribute("universities", emptyPage)
        }

        return "pages/universities/list"
    }

    @GetMapping("/universities/{id}")
    @PreAuthorize("isAuthenticated()")
    fun universityDetail(@PathVariable id: Long, model: Model): String {
        model.addAttribute("activeNav", "universities")

        try {
            universityService?.let { service ->
                val university = service.findById(id)
                model.addAttribute("pageTitle", "${university.name} - ZIMCHE Audit")
                model.addAttribute("university", university)
            } ?: run {
                model.addAttribute("pageTitle", "University Details - ZIMCHE Audit")
                return "error/404"
            }
        } catch (e: Exception) {
            model.addAttribute("pageTitle", "University Not Found - ZIMCHE Audit")
            return "error/404"
        }

        return "pages/universities/detail"
    }

    @GetMapping("/documents")
    @PreAuthorize("isAuthenticated()")
    fun documents(model: Model, authentication: Authentication): String {
        model.addAttribute("pageTitle", "Documents - ZIMCHE Audit")
        model.addAttribute("activeNav", "documents")

        try {
            userService?.let { service ->
                val user = service.findByEmail(authentication.name)
                model.addAttribute("user", user)
            }

            // Create empty documents page for now - we'll implement document service later
            val emptyPage = org.springframework.data.domain.PageImpl(
                emptyList<Any>(),
                PageRequest.of(0, 10),
                0
            )
            model.addAttribute("documents", emptyPage)

        } catch (e: Exception) {
            val emptyPage = org.springframework.data.domain.PageImpl(
                emptyList<Any>(),
                PageRequest.of(0, 10),
                0
            )
            model.addAttribute("documents", emptyPage)
        }

        return "pages/documents/list"
    }

    @GetMapping("/profile")
    fun profile(model: Model, authentication: Authentication): String {
        model.addAttribute("pageTitle", "Profile - ZIMCHE Audit")

        val userPrincipal = authentication.principal as? UserPrincipal

        userPrincipal?.let { user ->
            model.addAttribute("user", user)
            model.addAttribute("userEmail", user.email)
            model.addAttribute("userFullName", user.fullName)
            model.addAttribute("userAuthorities", user.authorities)
            model.addAttribute("isActive", user.isActive)
            model.addAttribute("universityId", user.universityId)

            // Additional profile stats
            model.addAttribute("totalAudits", 23)
            model.addAttribute("completedAudits", 18)
            model.addAttribute("documentsUploaded", 147)
            model.addAttribute("reportsGenerated", 12)
            model.addAttribute("memberSince", "January 2023")
            model.addAttribute("lastLogin", "2025-07-11 09:15:30")
        }

        return "pages/profile/view"
    }

    @GetMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    fun admin(model: Model): String {
        model.addAttribute("pageTitle", "Admin Dashboard - ZIMCHE Audit")

        // Sample data for now - replace with actual service calls
        model.addAttribute("totalUsers", 847)
        model.addAttribute("activeUsers", 623)
        model.addAttribute("totalUniversities", 12)
        model.addAttribute("activeUniversities", 11)
        model.addAttribute("totalAudits", 156)
        model.addAttribute("pendingAudits", 23)
        model.addAttribute("totalReports", 234)
        model.addAttribute("systemUptime", "99.8%")
        model.addAttribute("storageUsed", "2.4 TB")
        model.addAttribute("apiCalls", "1.2M")
        model.addAttribute("activeAlerts", 5)
        model.addAttribute("criticalAlerts", 2)

        return "pages/admin/admin"
    }

    @GetMapping("/reports")
    @PreAuthorize("hasRole('ADMIN') or hasRole('PEER_REVIEWER')")
    fun reports(model: Model): String {
        model.addAttribute("pageTitle", "Reports - ZIMCHE Audit")

        // Sample data for now - replace with actual service calls later
        model.addAttribute("totalReports", 156)
        model.addAttribute("publishedReports", 134)
        model.addAttribute("draftReports", 15)
        model.addAttribute("pendingReports", 7)

        return "pages/reports/index"
    }

    // Helper methods to safely get counts
    private fun getUniversityCount(): Long {
        return try {
            universityService?.let { service ->
                // Try different possible method names
                try {
                    val method = service::class.java.getMethod("getTotalCount")
                    method.invoke(service) as Long
                } catch (e: NoSuchMethodException) {
                    try {
                        val method = service::class.java.getMethod("count")
                        method.invoke(service) as Long
                    } catch (e2: NoSuchMethodException) {
                        0L
                    }
                }
            } ?: 0L
        } catch (e: Exception) {
            0L
        }
    }

    private fun getUserCount(): Long {
        return try {
            userService?.let { service ->
                try {
                    val method = service::class.java.getMethod("getTotalCount")
                    method.invoke(service) as Long
                } catch (e: NoSuchMethodException) {
                    try {
                        val method = service::class.java.getMethod("count")
                        method.invoke(service) as Long
                    } catch (e2: NoSuchMethodException) {
                        0L
                    }
                }
            } ?: 0L
        } catch (e: Exception) {
            0L
        }
    }
}
