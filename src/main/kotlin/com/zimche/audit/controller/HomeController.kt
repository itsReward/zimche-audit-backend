package com.zimche.audit.controller

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api")
class HomeController {

    @GetMapping("/")
    fun home(): String {
        return "ZIMCHE Audit System API is running"
    }
}