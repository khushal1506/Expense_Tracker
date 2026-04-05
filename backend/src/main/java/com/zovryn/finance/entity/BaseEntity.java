package com.zovryn.finance.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.springframework.data.domain.Persistable;

import java.time.Instant;
import java.util.UUID;

@MappedSuperclass
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public abstract class BaseEntity implements Persistable<UUID> {

    @Id
    @Column(columnDefinition = "UUID")
    private UUID id;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private Instant updatedAt;

    @Column(nullable = false)
    private Boolean isDeleted = false;

    @Column(nullable = false)
    private Boolean isSynced = false;

    @PrePersist
    protected void onCreate() {
        if (this.id == null) {
            this.id = UUID.randomUUID();
        }
        if (this.isDeleted == null) {
            this.isDeleted = false;
        }
        if (this.isSynced == null) {
            this.isSynced = false;
        }
    }

    @Override
    public UUID getId() {
        return id;
    }

    @Override
    @Transient
    public boolean isNew() {
        return createdAt == null;
    }
}
