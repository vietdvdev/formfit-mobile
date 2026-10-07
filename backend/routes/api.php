<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\CoachController;

/*
|--------------------------------------------------------------------------
| FormFit API Routes (v1)
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // MARK: - Coach Marketplace Public Endpoints
    Route::get('/coaches', [CoachController::class, 'index']);
    Route::get('/coaches/{id}', [CoachController::class, 'show']);

    // MARK: - Coaching Private Endpoints (Cần xác thực Sanctum/JWT)
    Route::middleware('auth:sanctum')->group(function () {
        // Thuê Huấn luyện viên
        Route::post('/coaching/hire', [CoachController::class, 'hire']);

        // Chat Realtime 1-1 & Upload video sửa form động tác
        Route::get('/chat/contracts/{contractId}/messages', [\App\Http\Controllers\Api\V1\ChatController::class, 'getMessages']);
        Route::post('/chat/contracts/{contractId}/messages', [\App\Http\Controllers\Api\V1\ChatController::class, 'sendMessage']);
    });
});
