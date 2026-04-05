package com.zovryn.finance.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goals", indexes = {
    @Index(name = "idx_goal_user_id", columnList = "user_id"),
    @Index(name = "idx_goal_month", columnList = "month"),
    @Index(name = "idx_goal_updated_at", columnList = "updated_at")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Goal extends BaseEntity {

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal targetAmount;

    @Column(nullable = false)
    private String month; // Format: "YYYY-MM"

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    public Goal(UUID id, Instant createdAt, Instant updatedAt, Boolean isDeleted, Boolean isSynced,
               String name, BigDecimal targetAmount, String month, User user) {
        super(id, createdAt, updatedAt, isDeleted, isSynced);
        this.name = name;
        this.targetAmount = targetAmount;
        this.month = month;
        this.user = user;
    }
}
