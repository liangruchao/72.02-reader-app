package com.readerapp.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Set;

/**
 * User Info Response DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserInfoResponse {

    private String id;
    private String email;
    private String username;
    private String displayName;
    private String avatarUrl;
    private String bio;
    private String platformId;
    private boolean isActive;
    private boolean isEmailVerified;
    private Set<String> roles;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
