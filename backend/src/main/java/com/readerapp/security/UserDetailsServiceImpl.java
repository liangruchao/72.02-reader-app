package com.readerapp.security;

import com.readerapp.entity.User;
import com.readerapp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * User Details Service Implementation
 *
 * Loads user-specific data for Spring Security
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // In our case, username is the user ID (from JWT token)
        // But we also support email as username for initial authentication

        User user;

        // Check if username looks like a UUID (for JWT authentication)
        if (isValidUuid(username)) {
            // Try to find by ID (for JWT authentication)
            user = userRepository.findByIdWithRoles(username)
                    .orElseThrow(() -> new UsernameNotFoundException("User not found with id: " + username));
        } else {
            // Try to find by email (for initial login)
            user = userRepository.findByEmailWithRoles(username)
                    .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + username));
        }

        if (!user.getIsActive()) {
            throw new UsernameNotFoundException("User is not active: " + username);
        }

        log.debug("Loading user: {}", user.getEmail());

        return UserPrincipal.create(user);
    }

    /**
     * Check if the string is a valid UUID format
     */
    private boolean isValidUuid(String uuid) {
        if (uuid == null) {
            return false;
        }
        try {
            java.util.UUID.fromString(uuid);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    /**
     * Load user by email
     * This method is used for authentication
     */
    @Transactional(readOnly = true)
    public UserDetails loadUserByEmail(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmailWithRoles(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email));

        if (!user.getIsActive()) {
            throw new UsernameNotFoundException("User is not active: " + email);
        }

        log.debug("Loading user by email: {}", email);

        return UserPrincipal.create(user);
    }
}
