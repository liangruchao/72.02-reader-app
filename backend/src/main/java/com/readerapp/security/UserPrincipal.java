package com.readerapp.security;

import com.readerapp.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.stream.Collectors;

/**
 * User Principal
 *
 * Implements Spring Security UserDetails interface
 * Represents authenticated user in the system
 */
@Data
@Builder
@AllArgsConstructor
public class UserPrincipal implements UserDetails {

    private String id;
    private String email;
    private String username;
    private String password;
    private String platformId;
    private Collection<? extends GrantedAuthority> authorities;

    /**
     * Create UserPrincipal from User entity
     */
    public static UserPrincipal create(User user) {
        Collection<GrantedAuthority> authorities = user.getRoles().stream()
                .map(role -> new SimpleGrantedAuthority("ROLE_" + role.getName()))
                .collect(Collectors.toList());

        return UserPrincipal.builder()
                .id(user.getId())
                .email(user.getEmail())
                .username(user.getEmail()) // Use email as username
                .password(user.getPassword())
                .platformId(user.getPlatformId())
                .authorities(authorities)
                .build();
    }

    /**
     * Create UserPrincipal from User entity with custom authorities
     */
    public static UserPrincipal create(User user, Collection<GrantedAuthority> authorities) {
        return UserPrincipal.builder()
                .id(user.getId())
                .email(user.getEmail())
                .username(user.getEmail())
                .password(user.getPassword())
                .platformId(user.getPlatformId())
                .authorities(authorities)
                .build();
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true; // You can check user.is_active() here
    }
}
