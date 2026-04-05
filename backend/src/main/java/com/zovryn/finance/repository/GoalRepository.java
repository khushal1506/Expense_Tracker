package com.zovryn.finance.repository;

import com.zovryn.finance.entity.Goal;
import com.zovryn.finance.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface GoalRepository extends JpaRepository<Goal, UUID> {

    List<Goal> findAllByUserAndIsDeletedFalse(User user);

    List<Goal> findAllByUserAndIsDeletedFalseAndUpdatedAtAfter(User user, Instant since);

    @Query("SELECT g FROM Goal g WHERE g.user = :user AND g.isDeleted = false")
    List<Goal> findAllActiveByUser(@Param("user") User user);
}
