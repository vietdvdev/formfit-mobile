<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CoachProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'bio',
        'specialty',
        'certifications',
        'monthly_price',
        'rating',
        'review_count',
        'is_verified',
    ];

    protected $casts = [
        'certifications' => 'array',
        'monthly_price' => 'decimal:2',
        'rating' => 'decimal:2',
        'is_verified' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
