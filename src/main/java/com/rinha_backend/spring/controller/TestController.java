package com.rinha_backend.spring.controller;

import com.rinha_backend.spring.model.AppInfo;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/test")
public class TestController {

    private final AppInfo app;

    public TestController(AppInfo app) {
        this.app = app;
    }

    @GetMapping
    public ResponseEntity<String> get(){
        String response = "Hello, world! App - " + app.getAppName() + " // port: " + app.getAppPort();
        return ResponseEntity.ok(response);
    }
}
