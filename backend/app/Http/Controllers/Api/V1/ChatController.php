<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ChatMessage;
use App\Models\CoachingContract;
use App\Events\MessageSent;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ChatController extends Controller
{
    /**
     * GET /api/v1/chat/contracts/{contractId}/messages
     * Lấy lịch sử tin nhắn
     */
    public function getMessages(Request $request, int $contractId): JsonResponse
    {
        $userId = $request->user()->id ?? 1;

        $contract = CoachingContract::findOrFail($contractId);
        // Đảm bảo chỉ Học viên hoặc PT của hợp đồng này mới xem được
        if ($contract->student_id != $userId && $contract->coach_id != $userId) {
            return response()->json(['success' => false, 'message' => 'Bạn không có quyền truy cập kênh chat này.'], 403);
        }

        $messages = ChatMessage::with('sender:id,name,avatar_url')
            ->where('contract_id', $contractId)
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $messages
        ], 200);
    }

    /**
     * POST /api/v1/chat/contracts/{contractId}/messages
     * Gửi tin nhắn văn bản hoặc kèm media (Cloudflare R2 / AWS S3)
     */
    public function sendMessage(Request $request, int $contractId): JsonResponse
    {
        $validated = $request->validate([
            'message' => 'nullable|string|max:2000',
            'type' => 'required|in:text,video,image',
            'media_file' => 'nullable|file|mimes:mp4,mov,avi,jpg,jpeg,png,webp|max:102400', // Tối đa 100MB cho video sửa form
        ]);

        $userId = $request->user()->id ?? 1;

        $contract = CoachingContract::findOrFail($contractId);
        if ($contract->student_id != $userId && $contract->coach_id != $userId) {
            return response()->json(['success' => false, 'message' => 'Bạn không thuộc hợp đồng huấn luyện này.'], 403);
        }

        $mediaUrl = null;
        $thumbnailUrl = null;

        // Xử lý upload file lên Cloudflare R2 / AWS S3 CDN
        if ($request->hasFile('media_file')) {
            $file = $request->file('media_file');
            $extension = $file->getClientOriginalExtension();
            $fileName = Str::uuid()->toString() . '.' . $extension;
            $folder = ($validated['type'] === 'video') ? 'chat/videos' : 'chat/images';

            // Upload lên S3 disk (Cloudflare R2 tương thích S3 API)
            $path = Storage::disk(config('filesystems.default', 'public'))->putFileAs($folder, $file, $fileName);
            $mediaUrl = Storage::disk(config('filesystems.default', 'public'))->url($path);
        }

        $chatMessage = ChatMessage::create([
            'contract_id' => $contractId,
            'sender_id' => $userId,
            'message' => $validated['message'] ?? null,
            'type' => $validated['type'],
            'media_url' => $mediaUrl,
            'thumbnail_url' => $thumbnailUrl,
            'is_read' => false,
        ]);

        // Kích hoạt Broadcast sự kiện WebSocket Realtime tới đối tác
        broadcast(new MessageSent($chatMessage))->toOthers();

        return response()->json([
            'success' => true,
            'data' => $chatMessage->load('sender:id,name,avatar_url')
        ], 201);
    }
}
