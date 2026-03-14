package com.readerapp.repository;

import com.readerapp.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Role Repository
 */
@Repository
public interface RoleRepository extends JpaRepository<Role, String> {

    /**
     * Find role by name
     */
    Optional<Role> findByName(String name);

    /**
     * Check if role exists by name
     */
    boolean existsByName(String name);
}
