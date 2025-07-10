
package com.zimche.audit.util

import jakarta.annotation.PostConstruct
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.core.env.Environment
import org.springframework.stereotype.Component

/**
 * Utility class for checking Spring profiles
 */
@Component
class SpringProfileUtils {
    @Autowired
    private lateinit var environment: Environment
    
    companion object {
        private var instance: SpringProfileUtils? = null
        
        fun isDevProfile(): Boolean {
            val env = instance?.environment ?: return false
            return env.activeProfiles.contains("dev") || env.activeProfiles.isEmpty()
        }
        
        fun isProdProfile(): Boolean {
            val env = instance?.environment ?: return false
            return env.activeProfiles.contains("prod")
        }
    }
    
    @PostConstruct
    private fun init() {
        instance = this
    }
}