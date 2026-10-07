<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Bảng CoachProfile
        Schema::create('coach_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->text('bio')->nullable();
            $table->string('specialty')->default('General Fitness'); // Tăng cơ, Giảm mỡ, Thi đấu...
            $table->json('certifications')->nullable(); // Bằng cấp, chứng chỉ thể hình quốc tế (NASM, ISSA...)
            $table->decimal('monthly_price', 12, 2)->default(0.00); // Học phí theo tháng (VND)
            $table->decimal('rating', 3, 2)->default(5.00); // Điểm đánh giá trung bình (1.0 -> 5.0)
            $table->unsignedInteger('review_count')->default(0);
            $table->boolean('is_verified')->default(false); // Đã được admin phê duyệt chứng chỉ chưa
            $table->timestamps();

            $table->index(['monthly_price', 'rating', 'is_verified']);
        });

        // 2. Bảng CoachingContract
        Schema::create('coaching_contracts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('coach_id')->constrained('users')->cascadeOnDelete();
            $table->enum('status', ['pending', 'active', 'expired', 'cancelled'])->default('pending');
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->decimal('total_amount', 12, 2)->default(0.00);
            $table->text('student_note')->nullable();
            $table->timestamps();

            $table->index(['student_id', 'coach_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('coaching_contracts');
        Schema::dropIfExists('coach_profiles');
    }
};
