package com.zovryn.finance.repository;

import com.zovryn.finance.entity.Transaction;
import com.zovryn.finance.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    List<Transaction> findAllByUserAndIsDeletedFalse(User user);

    List<Transaction> findAllByUserAndIsDeletedFalseAndUpdatedAtAfter(User user, Instant since);

    @Query("SELECT t FROM Transaction t WHERE t.user = :user AND t.isDeleted = false")
    List<Transaction> findAllActiveByUser(@Param("user") User user);
}
