package com.readerapp.service;

import com.readerapp.dto.request.LoginRequest;
import com.readerapp.dto.request.RegisterRequest;
import com.readerapp.dto.response.AuthResponse;
import com.readerapp.dto.response.UserInfoResponse;
import com.readerapp.entity.Role;
import com.readerapp.entity.User;
import com.readerapp.repository.RoleRepository;
import com.readerapp.repository.UserRepository;
import com.readerapp.security.JWTTokenProvider;
import com.readerapp.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Authentication Service
 *
 * Handles user registration, login, and token management
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final AuthenticationManager authenticationManager;
    private final JWTTokenProvider tokenProvider;
    private final PasswordEncoder passwordEncoder;

    /**
     * Register new user
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        log.info("Registering new user with email: {}", request.getEmail());

        // Check if email already exists
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already registered");
        }

        // Check if username already exists (if provided)
        if (request.getUsername() != null && !request.getUsername().isBlank()) {
            if (userRepository.existsByUsername(request.getUsername())) {
                throw new RuntimeException("Username already taken");
            }
        }

        // Create new user
        User user = User.builder()
                .id(UUID.randomUUID().toString())
                .email(request.getEmail())
                .username(request.getUsername() != null ? request.getUsername() : request.getEmail().split("@")[0])
                .displayName(request.getDisplayName() != null ? request.getDisplayName() : request.getUsername())
                .password(passwordEncoder.encode(request.getPassword()))
                .isActive(true)
                .isEmailVerified(false)
                .roles(new HashSet<>())
                .build();

        // Assign default USER role
        Role userRole = roleRepository.findByName("USER")
                .orElseThrow(() -> new RuntimeException("Default USER role not found"));
        user.addRole(userRole);

        // Save user
        user = userRepository.save(user);

        log.info("User registered successfully with ID: {}", user.getId());

        // Generate tokens
        UserPrincipal userPrincipal = UserPrincipal.create(user);
        Authentication authentication = new UsernamePasswordAuthenticationToken(
                userPrincipal,
                null,
                userPrincipal.getAuthorities()
        );

        String accessToken = tokenProvider.generateAccessToken(authentication);
        String refreshToken = tokenProvider.generateRefreshToken(authentication);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(tokenProvider.getExpirationDateFromToken(accessToken).getTime() - System.currentTimeMillis())
                .refreshExpiresIn(tokenProvider.getExpirationDateFromToken(refreshToken).getTime() - System.currentTimeMillis())
                .userId(user.getId())
                .email(user.getEmail())
                .username(user.getUsername())
                .displayName(user.getDisplayName())
                .build();
    }

    /**
     * Login user
     */
    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        log.info("User login attempt with email: {}", request.getEmail());

        // Authenticate user
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();

        // Generate tokens
        String accessToken = tokenProvider.generateAccessToken(authentication);
        String refreshToken = tokenProvider.generateRefreshToken(authentication);

        log.info("User logged in successfully: {}", userPrincipal.getEmail());

        // Load user from database to get latest info
        User user = userRepository.findByEmailWithRoles(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(tokenProvider.getExpirationDateFromToken(accessToken).getTime() - System.currentTimeMillis())
                .refreshExpiresIn(tokenProvider.getExpirationDateFromToken(refreshToken).getTime() - System.currentTimeMillis())
                .userId(user.getId())
                .email(user.getEmail())
                .username(user.getUsername())
                .displayName(user.getDisplayName())
                .build();
    }

    /**
     * Refresh access token
     */
    @Transactional(readOnly = true)
    public AuthResponse refreshToken(String refreshToken) {
        log.info("Refreshing access token");

        // Validate refresh token
        if (!tokenProvider.validateToken(refreshToken)) {
            throw new RuntimeException("Invalid refresh token");
        }

        // Check token type
        String tokenType = tokenProvider.getTokenType(refreshToken);
        if (!"refresh".equals(tokenType)) {
            throw new RuntimeException("Invalid token type");
        }

        // Get user ID from token
        String userId = tokenProvider.getUserIdFromToken(refreshToken);

        // Load user
        User user = userRepository.findByIdWithRoles(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!user.getIsActive()) {
            throw new RuntimeException("User is not active");
        }

        // Generate new tokens
        UserPrincipal userPrincipal = UserPrincipal.create(user);
        Authentication authentication = new UsernamePasswordAuthenticationToken(
                userPrincipal,
                null,
                userPrincipal.getAuthorities()
        );

        String newAccessToken = tokenProvider.generateAccessToken(authentication);
        String newRefreshToken = tokenProvider.generateRefreshToken(authentication);

        log.info("Access token refreshed for user: {}", user.getEmail());

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .expiresIn(tokenProvider.getExpirationDateFromToken(newAccessToken).getTime() - System.currentTimeMillis())
                .refreshExpiresIn(tokenProvider.getExpirationDateFromToken(newRefreshToken).getTime() - System.currentTimeMillis())
                .userId(user.getId())
                .email(user.getEmail())
                .username(user.getUsername())
                .displayName(user.getDisplayName())
                .build();
    }

    /**
     * Get current user info
     */
    @Transactional(readOnly = true)
    public UserInfoResponse getCurrentUser(String userId) {
        User user = userRepository.findByIdWithRoles(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Set<String> roleNames = user.getRoles().stream()
                .map(Role::getName)
                .collect(Collectors.toSet());

        return UserInfoResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .username(user.getUsername())
                .displayName(user.getDisplayName())
                .avatarUrl(user.getAvatarUrl())
                .bio(user.getBio())
                .platformId(user.getPlatformId())
                .isActive(user.getIsActive())
                .isEmailVerified(user.getIsEmailVerified())
                .roles(roleNames)
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}
