package com.zovryn.finance.controller;

import com.zovryn.finance.dto.ApiResponse;
import com.zovryn.finance.dto.GoalDto;
import com.zovryn.finance.service.GoalService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/goals")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", maxAge = 3600)
public class GoalController {

    private final GoalService goalService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<GoalDto>>> getGoals() {
        List<GoalDto> goals = goalService.getUserGoals();
        return ResponseEntity.ok(ApiResponse.success(goals, "Goals retrieved successfully"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<GoalDto>> getGoal(@PathVariable UUID id) {
        GoalDto goal = goalService.getGoalById(id);
        return ResponseEntity.ok(ApiResponse.success(goal, "Goal retrieved successfully"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<GoalDto>> createGoal(@Valid @RequestBody GoalDto dto) {
        GoalDto goal = goalService.createGoal(dto);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success(goal, "Goal created successfully"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<GoalDto>> updateGoal(
            @PathVariable UUID id,
            @Valid @RequestBody GoalDto dto) {
        GoalDto goal = goalService.updateGoal(id, dto);
        return ResponseEntity.ok(ApiResponse.success(goal, "Goal updated successfully"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteGoal(@PathVariable UUID id) {
        goalService.deleteGoal(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Goal deleted successfully"));
    }
}
