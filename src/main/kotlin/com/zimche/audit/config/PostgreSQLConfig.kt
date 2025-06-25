package com.zimche.audit.config

import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Profile
import jakarta.annotation.PostConstruct
import org.springframework.beans.factory.annotation.Autowired
import javax.sql.DataSource
import java.sql.Connection

@Configuration
@Profile("!test")
class PostgreSQLConfig {

    @Autowired
    private lateinit var dataSource: DataSource

    @PostConstruct
    fun configurePostgreSQL() {
        try {
            dataSource.connection.use { connection ->
                // Set PostgreSQL specific settings
                executeStatement(connection, "SET timezone = 'UTC'")
                executeStatement(connection, "SET statement_timeout = '30s'")
                executeStatement(connection, "SET lock_timeout = '10s'")
            }
        } catch (e: Exception) {
            println("Warning: Could not configure PostgreSQL settings: ${e.message}")
        }
    }

    private fun executeStatement(connection: Connection, sql: String) {
        try {
            connection.createStatement().use { statement ->
                statement.execute(sql)
            }
        } catch (e: Exception) {
            println("Warning: Could not execute SQL: $sql - ${e.message}")
        }
    }
}
