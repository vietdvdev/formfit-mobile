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
        Schema::create('chat_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('contract_id')->constrained('coaching_contracts')->cascadeOnDelete();
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $table->text('message')->nullable();
            $table->enum('type', ['text', 'video', 'image'])->default('text');
            $table->string('media_url')->nullable();
            $table->string('thumbnail_url')->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamps();

            $table->index(['contract_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('chat_messages');
    }
};
