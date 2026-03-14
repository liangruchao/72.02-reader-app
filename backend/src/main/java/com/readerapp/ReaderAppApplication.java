package com.readerapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

/**
 * Reader Application Main Entry Point
 *
 * <p>A production-grade cross-platform reading application backend service.
 * Supports web, desktop (Tauri), and mobile (iOS/Android) clients.
 *
 * <p>Features:
 * - Article saving and reading
 * - Highlight and annotation management
 * - Tag and folder organization
 * - Real-time sync with CRDT support
 * - B2B2C multi-tenant architecture
 * - License management and billing
 * - WeChat and Google ecosystem integration
 *
 * @author Reader App Team
 * @version 1.0.0
 */
@SpringBootApplication
@EnableJpaAuditing
public class ReaderAppApplication {

    public static void main(String[] args) {
        SpringApplication.run(ReaderAppApplication.class, args);
    }
}
