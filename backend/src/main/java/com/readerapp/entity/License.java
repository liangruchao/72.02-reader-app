package com.readerapp.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

/**
 * License Entity
 *
 * Represents a software license purchased by a platform. Licenses determine
 * the features, user limits, and usage quotas for a platform.
 */
@Entity
@Table(name = "licenses")
@EntityListeners(AuditingEntityListener.class)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class License {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private String id;

    @Column(name = "platform_id", nullable = false)
    private String platformId;

    @Column(name = "license_key", nullable = false, unique = true, length = 500)
    private String key;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    @Builder.Default
    private LicenseType type = LicenseType.SUBSCRIPTION;

    @Enumerated(EnumType.STRING)
    @Column(name = "tier", nullable = false, length = 20)
    @Builder.Default
    private LicenseTier tier = LicenseTier.BASIC;

    @Column(name = "max_users")
    private Integer maxUsers;

    @Column(name = "max_articles")
    private Long maxArticles;

    @Column(name = "max_storage")
    private Long maxStorage; // in bytes

    @ElementCollection
    @CollectionTable(name = "license_features", joinColumns = @JoinColumn(name = "license_id"))
    @Column(name = "feature")
    @Builder.Default
    private Set<String> features = new HashSet<>();

    @Column(name = "start_date", nullable = false)
    private LocalDateTime startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDateTime endDate;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "auto_renew", nullable = false)
    @Builder.Default
    private Boolean autoRenew = false;

    @OneToMany(mappedBy = "license", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private Set<Subscription> subscriptions = new HashSet<>();

    @OneToMany(mappedBy = "license")
    @Builder.Default
    private Set<Platform> platforms = new HashSet<>();

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    /**
     * Check if license is expired
     */
    public boolean isExpired() {
        return LocalDateTime.now().isAfter(endDate);
    }

    /**
     * Check if license is valid
     */
    public boolean isValid() {
        return isActive && !isExpired();
    }
}
