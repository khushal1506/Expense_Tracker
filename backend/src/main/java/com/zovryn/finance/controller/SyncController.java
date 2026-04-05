package com.zovryn.finance.controller;

import com.zovryn.finance.dto.ApiResponse;
import com.zovryn.finance.dto.SyncPullResponse;
import com.zovryn.finance.dto.SyncPushRequest;
import com.zovryn.finance.dto.SyncPushResponse;
import com.zovryn.finance.service.SyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

@RestController
@RequestMapping("/api/sync")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", maxAge = 3600)
public class SyncController {

    private final SyncService syncService;

    @PostMapping("/push")
    public ResponseEntity<ApiResponse<SyncPushResponse>> syncPush(@RequestBody SyncPushRequest request) {
        SyncPushResponse response = syncService.syncPush(request);
        return ResponseEntity.ok(ApiResponse.success(response, "Sync push completed"));
    }

    @GetMapping("/pull")
    public ResponseEntity<ApiResponse<SyncPullResponse>> syncPull(
            @RequestParam(required = false) String since) {
        Instant sinceTimestamp = since != null ? Instant.parse(since) : Instant.EPOCH;
        SyncPullResponse response = syncService.syncPull(sinceTimestamp);
        return ResponseEntity.ok(ApiResponse.success(response, "Sync pull completed"));
    }
}
