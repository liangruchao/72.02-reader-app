package com.readerapp.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Authentication Response DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    private String accessToken;
    private String refreshToken;
    private String tokenType = "Bearer";
    private Long expiresIn; // Access token expiration in seconds
    private Long refreshExpiresIn; // Refresh token expiration in seconds
    private String userId;
    private String email;
    private String username;
    private String displayName;
}
