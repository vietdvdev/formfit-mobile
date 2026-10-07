<?php

namespace App\Events;

use App\Models\ChatMessage;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public ChatMessage $message;

    /**
     * Khởi tạo sự kiện gửi tin nhắn
     */
    public function __construct(ChatMessage $message)
    {
        $this->message = $message->load('sender:id,name,avatar_url');
    }

    /**
     * Broadcast lên private channel: chat.{contract_id}
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('chat.' . $this->message->contract_id),
        ];
    }

    /**
     * Tên sự kiện broadcast phía Client
     */
    public function broadcastAs(): string
    {
        return 'message.sent';
    }

    /**
     * Dữ liệu gửi qua WebSocket (Laravel Reverb)
     */
    public function broadcastWith(): array
    {
        return [
            'id' => $this->message->id,
            'contract_id' => $this->message->contract_id,
            'sender_id' => $this->message->sender_id,
            'sender_name' => $this->message->sender->name ?? 'Người dùng',
            'message' => $this->message->message,
            'type' => $this->message->type,
            'media_url' => $this->message->media_url,
            'thumbnail_url' => $this->message->thumbnail_url,
            'created_at' => $this->message->created_at->toIso8601String(),
        ];
    }
}
