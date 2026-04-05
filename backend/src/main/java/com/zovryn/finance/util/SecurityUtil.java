package com.zovryn.finance.util;

import com.zovryn.finance.entity.User;
import com.zovryn.finance.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class SecurityUtil {

    private static final String USER_EMAIL_HEADER = "X-User-Email";
    private static final String CLIENT_ID_HEADER = "X-Client-Id";
    private static final String DEFAULT_USER_EMAIL = "local.user@zovryn.dev";

    private final UserRepository userRepository;
    private final HttpServletRequest request;

    public SecurityUtil(UserRepository userRepository, HttpServletRequest request) {
        this.userRepository = userRepository;
        this.request = request;
    }

    public UUID getCurrentUserId() {
        return getCurrentUser().getId();
    }

    public User getCurrentUser() {
        String email = resolveCurrentUserEmail();

        return userRepository.findByEmail(email).orElseGet(() -> {
            User defaultUser = User.builder()
                    .email(email)
                    .name("Local User")
                    .passwordHash("no-auth")
                    .build();
            return userRepository.save(defaultUser);
        });
    }

    private String resolveCurrentUserEmail() {
        String userEmailHeader = request.getHeader(USER_EMAIL_HEADER);
        if (userEmailHeader != null && !userEmailHeader.isBlank()) {
            return userEmailHeader.trim().toLowerCase();
        }

        String clientId = request.getHeader(CLIENT_ID_HEADER);
        if (clientId != null && !clientId.isBlank()) {
            String normalizedClientId = clientId.trim().toLowerCase().replaceAll("[^a-z0-9._-]", "");
            if (!normalizedClientId.isBlank()) {
                return "client." + normalizedClientId + "@zovryn.dev";
            }
        }

        return DEFAULT_USER_EMAIL;
    }
}
