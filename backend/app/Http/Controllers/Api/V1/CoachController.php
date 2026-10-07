<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\CoachProfile;
use App\Models\CoachingContract;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class CoachController extends Controller
{
    /**
     * GET /api/v1/coaches
     * Danh sách Huấn luyện viên (Lọc theo giá, đánh giá, chuyên môn, verified)
     */
    public function index(Request $request): JsonResponse
    {
        $query = CoachProfile::with(['user:id,name,email,avatar_url'])
            ->where('is_verified', true);

        // Lọc theo Chuyên môn (Specialty)
        if ($request->filled('specialty')) {
            $query->where('specialty', 'like', '%' . $request->query('specialty') . '%');
        }

        // Lọc theo Khoảng giá (Min/Max monthly_price)
        if ($request->filled('min_price')) {
            $query->where('monthly_price', '>=', (float) $request->query('min_price'));
        }
        if ($request->filled('max_price')) {
            $query->where('monthly_price', '<=', (float) $request->query('max_price'));
        }

        // Lọc theo Điểm đánh giá (Rating)
        if ($request->filled('min_rating')) {
            $query->where('rating', '>=', (float) $request->query('min_rating'));
        }

        // Sắp xếp (sort_by: rating, price_asc, price_desc)
        $sortBy = $request->query('sort_by', 'rating_desc');
        switch ($sortBy) {
            case 'price_asc':
                $query->orderBy('monthly_price', 'asc');
                break;
            case 'price_desc':
                $query->orderBy('monthly_price', 'desc');
                break;
            case 'rating_desc':
            default:
                $query->orderBy('rating', 'desc')->orderBy('review_count', 'desc');
                break;
        }

        $perPage = (int) $request->query('per_page', 15);
        $coaches = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $coaches->items(),
            'pagination' => [
                'current_page' => $coaches->currentPage(),
                'per_page' => $coaches->perPage(),
                'total' => $coaches->total(),
                'last_page' => $coaches->lastPage(),
            ]
        ], 200);
    }

    /**
     * GET /api/v1/coaches/{id}
     * Xem chi tiết hồ sơ PT
     */
    public function show(int $id): JsonResponse
    {
        $coach = CoachProfile::with(['user:id,name,email,avatar_url,created_at'])
            ->where('id', $id)
            ->first();

        if (!$coach) {
            return response()->json([
                'success' => false,
                'message' => 'Không tìm thấy hồ sơ Huấn luyện viên.'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $coach
        ], 200);
    }

    /**
     * POST /api/v1/coaching/hire
     * Học viên tạo yêu cầu thuê Huấn luyện viên
     */
    public function hire(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'coach_user_id' => 'required|exists:users,id',
            'duration_months' => 'required|integer|min:1|max:12',
            'student_note' => 'nullable|string|max:500',
        ]);

        $studentId = $request->user()->id ?? $request->input('mock_student_id', 1);

        // Kiểm tra không cho phép tự thuê chính mình
        if ($studentId == $validated['coach_user_id']) {
            return response()->json([
                'success' => false,
                'message' => 'Bạn không thể tự thuê chính mình làm huấn luyện viên.'
            ], 422);
        }

        // Lấy profile PT để tính toán học phí
        $coachProfile = CoachProfile::where('user_id', $validated['coach_user_id'])->first();
        if (!$coachProfile) {
            return response()->json([
                'success' => false,
                'message' => 'Người dùng này chưa đăng ký hồ sơ Huấn luyện viên.'
            ], 404);
        }

        // Kiểm tra xem đã có hợp đồng nào đang active chưa
        $existingContract = CoachingContract::where('student_id', $studentId)
            ->where('coach_id', $validated['coach_user_id'])
            ->whereIn('status', ['pending', 'active'])
            ->first();

        if ($existingContract) {
            return response()->json([
                'success' => false,
                'message' => 'Bạn đã có một hợp đồng huấn luyện đang chờ duyệt hoặc đang có hiệu lực với PT này.',
                'contract_id' => $existingContract->id,
            ], 409);
        }

        $durationMonths = (int) $validated['duration_months'];
        $totalAmount = $coachProfile->monthly_price * $durationMonths;
        $startDate = now()->toDateString();
        $endDate = now()->addMonths($durationMonths)->toDateString();

        $contract = CoachingContract::create([
            'student_id' => $studentId,
            'coach_id' => $validated['coach_user_id'],
            'status' => 'pending', // Chờ PT đồng ý hoặc thanh toán
            'start_date' => $startDate,
            'end_date' => $endDate,
            'total_amount' => $totalAmount,
            'student_note' => $validated['student_note'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Yêu cầu thuê Huấn luyện viên đã được gửi thành công.',
            'data' => [
                'contract_id' => $contract->id,
                'coach_name' => $coachProfile->user->name ?? 'Huấn luyện viên',
                'status' => $contract->status,
                'total_amount' => $contract->total_amount,
                'start_date' => $contract->start_date->toDateString(),
                'end_date' => $contract->end_date->toDateString(),
            ]
        ], 201);
    }
}
