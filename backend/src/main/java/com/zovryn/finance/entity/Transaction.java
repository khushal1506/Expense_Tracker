package com.zovryn.finance.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "transactions", indexes = {
    @Index(name = "idx_user_id", columnList = "user_id"),
    @Index(name = "idx_date", columnList = "date"),
    @Index(name = "idx_updated_at", columnList = "updated_at")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Transaction extends BaseEntity {

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal amount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TransactionType type;

    @Column(nullable = false)
    private String category;

    @Column(nullable = false)
    private LocalDate date;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    public Transaction(UUID id, Instant createdAt, Instant updatedAt, Boolean isDeleted, Boolean isSynced,
                      BigDecimal amount, TransactionType type, String category, LocalDate date, String notes, User user) {
        super(id, createdAt, updatedAt, isDeleted, isSynced);
        this.amount = amount;
        this.type = type;
        this.category = category;
        this.date = date;
        this.notes = notes;
        this.user = user;
    }

    public enum TransactionType {
        INCOME, EXPENSE
    }
}
