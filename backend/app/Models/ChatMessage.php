<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatMessage extends Model
{
    use HasFactory;

    protected $fillable = [
        'contract_id',
        'sender_id',
        'message',
        'type',
        'media_url',
        'thumbnail_url',
        'is_read',
    ];

    protected $casts = [
        'is_read' => 'boolean',
    ];

    public function contract(): BelongsTo
    {
        return $this->belongsTo(CoachingContract::class, 'contract_id');
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
