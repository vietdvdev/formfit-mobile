<?php

namespace App\Policies;

use App\Models\User;
use App\Models\CoachingContract;
use Illuminate\Auth\Access\HandlesAuthorization;
use Illuminate\Auth\Access\Response;

class CoachingPolicy
{
    use HandlesAuthorization;

    /**
     * Xác thực: Huấn luyện viên chỉ có quyền tạo hoặc gán giáo án vào tài khoản của học viên
     * khi giữa 2 người có hợp đồng huấn luyện với trạng thái 'active'.
     */
    public function assignRoutine(User $coach, User $student): Response
    {
        // 1. Kiểm tra tài khoản người thao tác có hồ sơ PT không
        if (!$coach->coachProfile) {
            return Response::deny('Bạn không có quyền Huấn luyện viên (Coach Profile không tồn tại).');
        }

        // 2. Kiểm tra hợp đồng huấn luyện còn hiệu lực giữa PT và Học viên này
        $hasActiveContract = CoachingContract::where('coach_id', $coach->id)
            ->where('student_id', $student->id)
            ->active()
            ->exists();

        if ($hasActiveContract) {
            return Response::allow();
        }

        return Response::deny('Bạn không thể gán giáo án cho học viên này vì không có hợp đồng huấn luyện đang hoạt động (Active).');
    }

    /**
     * Quyền gửi phản hồi chỉnh sửa form động tác
     */
    public function provideFormFeedback(User $coach, User $student): Response
    {
        return $this->assignRoutine($coach, $student);
    }
}
