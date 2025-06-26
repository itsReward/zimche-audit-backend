package com.zimche.audit

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.data.jpa.repository.config.EnableJpaAuditing
import org.springframework.scheduling.annotation.EnableAsync
import org.springframework.transaction.annotation.EnableTransactionManagement

@SpringBootApplication
@EnableAsync
@EnableTransactionManagement
class ZimcheAuditApplication

fun main(args: Array<String>) {
    runApplication<ZimcheAuditApplication>(*args)
}
