package com.rinha_backend.spring.model;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class AppInfo {
    @Value("${app.name}")
    private String appName;

    @Value("${app.port}")
    private String appPort;

    public String getAppName() {
        return appName;
    }

    public String getAppPort() {
        return appPort;
    }
}
