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

        // Try to find by ID first (for JWT authentication)
        try {
            user = userRepository.findByIdWithRoles(username)
                    .orElseThrow(() -> new UsernameNotFoundException("User not found with id: " + username));
        } catch (IllegalArgumentException e) {
            // If not a valid UUID, try to find by email (for initial login)
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
