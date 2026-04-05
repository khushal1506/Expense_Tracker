package com.zovryn.finance.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "users", uniqueConstraints = {@UniqueConstraint(columnNames = "email")})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User extends BaseEntity {

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    @Column(nullable = false)
    private String name;

    @Builder.Default
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true, fetch = jakarta.persistence.FetchType.LAZY)
    private List<Transaction> transactions = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true, fetch = jakarta.persistence.FetchType.LAZY)
    private List<Goal> goals = new ArrayList<>();

    public User(UUID id, Instant createdAt, Instant updatedAt, Boolean isDeleted, Boolean isSynced,
                String email, String passwordHash, String name) {
        super(id, createdAt, updatedAt, isDeleted, isSynced);
        this.email = email;
        this.passwordHash = passwordHash;
        this.name = name;
        this.transactions = new ArrayList<>();
        this.goals = new ArrayList<>();
    }
}
