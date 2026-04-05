package com.zovryn.finance.config;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JacksonConfig {
    // Strict @JsonFormat is removed from DTO Instant fields.
    // Spring Boot auto-registers JavaTimeModule which uses DateTimeFormatter.ISO_INSTANT
    // for Instant deserialization — accepts any fractional-second precision (0–9 digits).
}
