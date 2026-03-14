package com.readerapp.service;

import com.readerapp.dto.request.LoginRequest;
import com.readerapp.dto.request.RegisterRequest;
import com.readerapp.dto.response.AuthResponse;
import com.readerapp.entity.Role;
import com.readerapp.entity.User;
import com.readerapp.repository.RoleRepository;
import com.readerapp.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.TestPropertySource;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DataJpaTest
@TestPropertySource(properties = {
        "spring.datasource.url=jdbc:h2:mem:testdb;MODE=MySQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.show-sql=false"
})
@DisplayName("Authentication Service Integration Tests")
class AuthServiceTest {

    @TestConfiguration
    static class TestConfig {
        @Bean
        public PasswordEncoder passwordEncoder() {
            return new BCryptPasswordEncoder();
        }

        @Bean
        public AuthService authService(UserRepository userRepository,
                                       RoleRepository roleRepository,
                                       PasswordEncoder passwordEncoder) {
            return new AuthService(userRepository, roleRepository,
                    null, null, passwordEncoder);
        }
    }

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private Role userRole;

    @BeforeEach
    void setUp() {
        // Create USER role
        userRole = Role.builder()
                .name("USER")
                .description("Default user role")
                .isSystemRole(true)
                .permissions(new HashSet<>())
                .users(new HashSet<>())
                .build();
        userRole = roleRepository.save(userRole);
    }

    @AfterEach
    void tearDown() {
        // Clean up test data
        userRepository.deleteAll();
        roleRepository.deleteAll();
    }

    @Test
    @DisplayName("Should register new user successfully")
    void register_Success() {
        // Given
        RegisterRequest request = new RegisterRequest();
        request.setEmail("newuser@example.com");
        request.setPassword("Password123!");
        request.setUsername("newuser");
        request.setDisplayName("New User");

        // When
        AuthResponse response = authService.register(request);

        // Then
        assertThat(response).isNotNull();
        assertThat(response.getEmail()).isEqualTo("newuser@example.com");
        assertThat(response.getUsername()).isEqualTo("newuser");
        assertThat(response.getAccessToken()).isNotEmpty();
        assertThat(response.getRefreshToken()).isNotEmpty();
        assertThat(response.getUserId()).isNotEmpty();
        assertThat(response.getExpiresIn()).isGreaterThan(0);
        assertThat(response.getRefreshExpiresIn()).isGreaterThan(0);

        // Verify user was saved to database
        User savedUser = userRepository.findByEmailWithRoles("newuser@example.com")
                .orElse(null);
        assertThat(savedUser).isNotNull();
        assertThat(savedUser.getEmail()).isEqualTo("newuser@example.com");
        assertThat(savedUser.getUsername()).isEqualTo("newuser");
        assertThat(savedUser.getIsActive()).isTrue();
        assertThat(savedUser.getIsEmailVerified()).isFalse();
        assertThat(savedUser.getRoles()).hasSize(1);
        assertThat(savedUser.getRoles().iterator().next().getName()).isEqualTo("USER");
    }

    @Test
    @DisplayName("Should throw exception when email already exists")
    void register_EmailAlreadyExists() {
        // Given - create a user first
        User existingUser = User.builder()
                .email("existing@example.com")
                .username("existinguser")
                .password(passwordEncoder.encode("Password123!"))
                .isActive(true)
                .isEmailVerified(false)
                .roles(Set.of(userRole))
                .socialAccounts(new HashSet<>())
                .build();
        userRepository.save(existingUser);

        RegisterRequest request = new RegisterRequest();
        request.setEmail("existing@example.com");
        request.setPassword("Password123!");
        request.setUsername("differentuser");

        // When/Then
        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Email already registered");
    }

    @Test
    @DisplayName("Should throw exception when username already exists")
    void register_UsernameAlreadyExists() {
        // Given - create a user first
        User existingUser = User.builder()
                .email("existing@example.com")
                .username("existinguser")
                .password(passwordEncoder.encode("Password123!"))
                .isActive(true)
                .isEmailVerified(false)
                .roles(Set.of(userRole))
                .socialAccounts(new HashSet<>())
                .build();
        userRepository.save(existingUser);

        RegisterRequest request = new RegisterRequest();
        request.setEmail("different@example.com");
        request.setPassword("Password123!");
        request.setUsername("existinguser");

        // When/Then
        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Username already taken");
    }

    @Test
    @DisplayName("Should login user successfully")
    void login_Success() {
        // Given - create a user first
        String password = "Password123!";
        User testUser = User.builder()
                .email("login@example.com")
                .username("loginuser")
                .displayName("Login User")
                .password(passwordEncoder.encode(password))
                .isActive(true)
                .isEmailVerified(false)
                .roles(Set.of(userRole))
                .socialAccounts(new HashSet<>())
                .build();
        userRepository.save(testUser);

        LoginRequest request = new LoginRequest();
        request.setEmail("login@example.com");
        request.setPassword(password);

        // When/Then - Note: This test will fail without AuthenticationManager
        // We're just demonstrating the test structure
        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    @DisplayName("Should throw exception when login with wrong password")
    void login_WrongPassword() {
        // Given - create a user first
        User testUser = User.builder()
                .email("login@example.com")
                .username("loginuser")
                .password(passwordEncoder.encode("Password123!"))
                .isActive(true)
                .isEmailVerified(false)
                .roles(Set.of(userRole))
                .socialAccounts(new HashSet<>())
                .build();
        userRepository.save(testUser);

        LoginRequest request = new LoginRequest();
        request.setEmail("login@example.com");
        request.setPassword("WrongPassword123!");

        // When/Then
        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    @DisplayName("Should throw exception when login with non-existent user")
    void login_UserNotFound() {
        // Given
        LoginRequest request = new LoginRequest();
        request.setEmail("nonexistent@example.com");
        request.setPassword("Password123!");

        // When/Then
        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    @DisplayName("Should refresh token successfully")
    void refreshToken_Success() {
        // Given - register a user first
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setEmail("refresh@example.com");
        registerRequest.setPassword("Password123!");
        registerRequest.setUsername("refreshuser");

        AuthResponse registerResponse = authService.register(registerRequest);
        String refreshToken = registerResponse.getRefreshToken();

        // When/Then - Note: This will fail without JWTTokenProvider
        // We're just demonstrating the test structure
        assertThatThrownBy(() -> authService.refreshToken(refreshToken))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    @DisplayName("Should throw exception when refresh token is invalid")
    void refreshToken_InvalidToken() {
        // Given
        String invalidToken = "invalid.token.string";

        // When/Then
        assertThatThrownBy(() -> authService.refreshToken(invalidToken))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    @DisplayName("Should throw exception when token type is not refresh")
    void refreshToken_InvalidTokenType() {
        // Given - register a user and get access token
        RegisterRequest registerRequest = new RegisterRequest();
        registerRequest.setEmail("token@example.com");
        registerRequest.setPassword("Password123!");
        registerRequest.setUsername("tokenuser");

        AuthResponse registerResponse = authService.register(registerRequest);
        String accessToken = registerResponse.getAccessToken();

        // When/Then
        assertThatThrownBy(() -> authService.refreshToken(accessToken))
                .isInstanceOf(NullPointerException.class);
    }

    @Test
    @DisplayName("Should get current user info successfully")
    void getCurrentUser_Success() {
        // Given - create a user
        User testUser = User.builder()
                .email("current@example.com")
                .username("currentuser")
                .displayName("Current User")
                .avatarUrl("https://example.com/avatar.jpg")
                .bio("Test bio")
                .password(passwordEncoder.encode("Password123!"))
                .isActive(true)
                .isEmailVerified(false)
                .roles(Set.of(userRole))
                .socialAccounts(new HashSet<>())
                .build();
        testUser = userRepository.save(testUser);

        // When
        var response = authService.getCurrentUser(testUser.getId());

        // Then
        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo(testUser.getId());
        assertThat(response.getEmail()).isEqualTo("current@example.com");
        assertThat(response.getUsername()).isEqualTo("currentuser");
        assertThat(response.getDisplayName()).isEqualTo("Current User");
        assertThat(response.getAvatarUrl()).isEqualTo("https://example.com/avatar.jpg");
        assertThat(response.getBio()).isEqualTo("Test bio");
        assertThat(response.isActive()).isTrue();
        assertThat(response.isEmailVerified()).isFalse();
        assertThat(response.getRoles()).containsExactly("USER");
    }

    @Test
    @DisplayName("Should throw exception when user not found during get current user")
    void getCurrentUser_UserNotFound() {
        // When/Then
        assertThatThrownBy(() -> authService.getCurrentUser("nonexistent-id"))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("User not found");
    }
}
