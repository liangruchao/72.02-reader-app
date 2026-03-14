package com.readerapp.controller;

import com.readerapp.dto.request.LoginRequest;
import com.readerapp.dto.request.RegisterRequest;
import com.readerapp.dto.response.ApiResponse;
import com.readerapp.dto.response.AuthResponse;
import com.readerapp.dto.response.UserInfoResponse;
import com.readerapp.security.UserPrincipal;
import com.readerapp.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * Authentication Controller
 *
 * Handles authentication endpoints: register, login, logout, refresh token
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /**
     * Register new user
     *
     * POST /api/v1/auth/register
     */
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody RegisterRequest request
    ) {
        log.info("Registration request for email: {}", request.getEmail());

        try {
            AuthResponse authResponse = authService.register(request);
            return ResponseEntity.ok(
                    ApiResponse.success("User registered successfully", authResponse)
            );
        } catch (RuntimeException e) {
            log.error("Registration failed: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Registration failed: " + e.getMessage()));
        }
    }

    /**
     * Login user
     *
     * POST /api/v1/auth/login
     */
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest request
    ) {
        log.info("Login request for email: {}", request.getEmail());

        try {
            AuthResponse authResponse = authService.login(request);
            return ResponseEntity.ok(
                    ApiResponse.success("Login successful", authResponse)
            );
        } catch (RuntimeException e) {
            log.error("Login failed: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Login failed: " + e.getMessage()));
        }
    }

    /**
     * Refresh access token
     *
     * POST /api/v1/auth/refresh
     */
    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(
            @RequestParam String refreshToken
    ) {
        log.info("Token refresh request");

        try {
            AuthResponse authResponse = authService.refreshToken(refreshToken);
            return ResponseEntity.ok(
                    ApiResponse.success("Token refreshed successfully", authResponse)
            );
        } catch (RuntimeException e) {
            log.error("Token refresh failed: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Token refresh failed: " + e.getMessage()));
        }
    }

    /**
     * Get current user info
     *
     * GET /api/v1/auth/me
     */
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserInfoResponse>> getCurrentUser(
            @AuthenticationPrincipal UserPrincipal userPrincipal
    ) {
        log.info("Get current user info request for user: {}", userPrincipal.getEmail());

        try {
            UserInfoResponse userInfo = authService.getCurrentUser(userPrincipal.getId());
            return ResponseEntity.ok(
                    ApiResponse.success("User info retrieved successfully", userInfo)
            );
        } catch (RuntimeException e) {
            log.error("Failed to get user info: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to get user info: " + e.getMessage()));
        }
    }

    /**
     * Logout user
     *
     * POST /api/v1/auth/logout
     * Note: JWT is stateless, client should discard the token
     */
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(
            @AuthenticationPrincipal UserPrincipal userPrincipal
    ) {
        log.info("Logout request for user: {}", userPrincipal.getEmail());

        // In a stateless JWT system, logout is handled on the client side
        // by discarding the token. Optionally, we can add the token to a blacklist.
        // For now, just return success.

        return ResponseEntity.ok(
                ApiResponse.<Void>success("Logout successful")
        );
    }
}
