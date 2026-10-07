<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CoachingContract extends Model
{
    use HasFactory;

    protected $fillable = [
        'student_id',
        'coach_id',
        'status',
        'start_date',
        'end_date',
        'total_amount',
        'student_note',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'total_amount' => 'decimal:2',
    ];

    public function student(): BelongsTo
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function coach(): BelongsTo
    {
        return $this->belongsTo(User::class, 'coach_id');
    }

    /**
     * Scope lọc các hợp đồng đang hoạt động
     */
    public function scopeActive($query)
    {
        return $query->where('status', 'active')
            ->where(function ($q) {
                $q->whereNull('end_date')
                  ->orWhere('end_date', '>=', now()->toDateString());
            });
    }
}
