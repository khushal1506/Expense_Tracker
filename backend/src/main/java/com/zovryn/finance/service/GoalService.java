package com.zovryn.finance.service;

import com.zovryn.finance.dto.GoalDto;
import com.zovryn.finance.entity.Goal;
import com.zovryn.finance.entity.User;
import com.zovryn.finance.exception.EntityNotFoundException;
import com.zovryn.finance.repository.GoalRepository;
import com.zovryn.finance.util.MapperUtil;
import com.zovryn.finance.util.SecurityUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GoalService {

    private final GoalRepository goalRepository;
    private final SecurityUtil securityUtil;

    @Transactional(readOnly = true)
    public List<GoalDto> getUserGoals() {
        User user = securityUtil.getCurrentUser();
        return goalRepository.findAllByUserAndIsDeletedFalse(user)
                .stream()
                .map(MapperUtil::toGoalDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<GoalDto> getUnsyncedGoals() {
        User user = securityUtil.getCurrentUser();
        return goalRepository.findAllByUserAndIsDeletedFalse(user)
                .stream()
                .filter(g -> !g.getIsSynced())
                .map(MapperUtil::toGoalDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public GoalDto getGoalById(UUID id) {
        User user = securityUtil.getCurrentUser();
        Goal goal = goalRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Goal not found"));

        if (!goal.getUser().getId().equals(user.getId())) {
            throw new EntityNotFoundException("Goal not owned by this user");
        }

        return MapperUtil.toGoalDto(goal);
    }

    @Transactional
    public GoalDto createGoal(GoalDto dto) {
        User user = securityUtil.getCurrentUser();
        Goal goal = MapperUtil.toGoalEntity(dto, user);
        goal = goalRepository.save(goal);
        return MapperUtil.toGoalDto(goal);
    }

    @Transactional
    public GoalDto updateGoal(UUID id, GoalDto dto) {
        User user = securityUtil.getCurrentUser();
        Goal goal = goalRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Goal not found"));

        if (!goal.getUser().getId().equals(user.getId())) {
            throw new EntityNotFoundException("Goal not owned by this user");
        }

        goal.setName(dto.getName());
        goal.setTargetAmount(dto.getTargetAmount());
        goal.setMonth(dto.getMonth());
        goal.setIsSynced(false);

        goal = goalRepository.save(goal);
        return MapperUtil.toGoalDto(goal);
    }

    @Transactional
    public void deleteGoal(UUID id) {
        User user = securityUtil.getCurrentUser();
        Goal goal = goalRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Goal not found"));

        if (!goal.getUser().getId().equals(user.getId())) {
            throw new EntityNotFoundException("Goal not owned by this user");
        }

        goal.setIsDeleted(true);
        goal.setIsSynced(false);
        goalRepository.save(goal);
    }

    @Transactional(readOnly = true)
    public List<GoalDto> getChangedSince(Instant since) {
        User user = securityUtil.getCurrentUser();
        return goalRepository.findAllByUserAndIsDeletedFalseAndUpdatedAtAfter(user, since)
                .stream()
                .map(MapperUtil::toGoalDto)
                .toList();
    }
}
