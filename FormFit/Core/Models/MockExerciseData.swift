import Foundation

public struct MockExerciseData {
    public static let sampleExercises: [ExerciseItem] = [
        ExerciseItem(
            name: "Đẩy tạ đòn trên ghế phẳng",
            englishName: "Barbell Bench Press",
            primaryMuscle: .chest,
            secondaryMuscles: ["Cơ vai trước", "Cơ tay sau"],
            equipment: .barbell,
            difficulty: .intermediate,
            thumbnailImageName: "figure.strengthtraining.traditional",
            model3DRemoteURL: URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/retrotv/tv_retro.usdz")!,
            targetMeshNodeNames: ["pectoralis_major", "deltoid_anterior"],
            instructions: [
                "Nằm ngửa trên ghế tập phẳng, mắt nhìn thẳng dưới thanh đòn. Đặt 2 chân vững chãi trên sàn.",
                "Nắm thanh đòn rộng hơn vai một chút, siết chặt hai bả vai áp sát mặt ghế.",
                "Tháo thanh tạ khỏi giá đỡ, hít một hơi sâu và gồng chặt cơ bụng.",
                "Hạ tạ có kiểm soát xuống điểm giữa ngực (Pha giãn cơ - Eccentric).",
                "Thở ra và dồn lực ngực đẩy tạ dứt khoát về vị trí ban đầu (Pha co cơ - Concentric)."
            ],
            commonMistakes: [
                "Ưỡn lưng quá cao làm mất kiểm soát cột sống.",
                "Để khuỷu tay mở góc 90 độ so với thân người gây chèn ép khớp vai.",
                "Nảy tạ lên từ lồng ngực."
            ]
        ),
        ExerciseItem(
            name: "Kéo xô cáp ngồi",
            englishName: "Seated Cable Row",
            primaryMuscle: .back,
            secondaryMuscles: ["Cơ tay trước", "Cơ trám"],
            equipment: .cable,
            difficulty: .beginner,
            thumbnailImageName: "figure.core.training",
            model3DRemoteURL: URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/retrotv/tv_retro.usdz")!,
            targetMeshNodeNames: ["latissimus_dorsi", "rhomboids"],
            instructions: [
                "Ngồi vào máy cáp, đặt chân lên bàn đạp, đầu gối hơi chùng tự nhiên.",
                "Cầm tay nắm chữ V, giữ lưng thẳng, ngực ưỡn nhẹ và khóa chặt xương bả vai.",
                "Thở ra và kéo tay cầm sát về phía bụng dưới, ép chặt hai xương bả vai lại với nhau.",
                "Giữ 1 giây ở đỉnh động tác rồi hít vào, từ từ thả tạ về phía trước có kiểm soát."
            ],
            commonMistakes: [
                "Đung đưa người dùng quán tính để giật tạ.",
                "Gù lưng khi kéo gây áp lực lên thắt lưng."
            ]
        ),
        ExerciseItem(
            name: "Gánh tạ đòn",
            englishName: "Barbell Back Squat",
            primaryMuscle: .legs,
            secondaryMuscles: ["Cơ mông", "Cơ đùi sau", "Cơ lõi"],
            equipment: .barbell,
            difficulty: .advanced,
            thumbnailImageName: "figure.run",
            model3DRemoteURL: URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/retrotv/tv_retro.usdz")!,
            targetMeshNodeNames: ["quadriceps", "gluteus_maximus"],
            instructions: [
                "Đặt thanh tạ đòn vững trên cơ cầu vai, hai chân đứng rộng bằng vai, mũi chân mở 15-30 độ.",
                "Hít sâu vào khoang bụng, siết chặt cơ lõi và giữ lưng thẳng.",
                "Đẩy hông ra sau và gập đầu gối hạ người xuống cho đến khi đùi song song hoặc dưới sàn.",
                "Dồn lực đều vào gót chân và giữa bàn chân đẩy mạnh mẽ đứng thẳng dậy."
            ],
            commonMistakes: [
                "Đầu gối chụm vào trong (Knee valgus) khi phát lực đứng lên.",
                "Nhấc gót chân lên khỏi sàn."
            ]
        ),
        ExerciseItem(
            name: "Đẩy tạ đơn qua đầu",
            englishName: "Dumbbell Shoulder Press",
            primaryMuscle: .shoulders,
            secondaryMuscles: ["Cơ tay sau", "Cơ ngực trên"],
            equipment: .dumbbell,
            difficulty: .intermediate,
            thumbnailImageName: "figure.boxing",
            model3DRemoteURL: URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/retrotv/tv_retro.usdz")!,
            targetMeshNodeNames: ["deltoid_lateral", "deltoid_anterior"],
            instructions: [
                "Ngồi thẳng lưng trên ghế có tựa, giữ 2 quả tạ đơn ngang tầm tai với lòng bàn tay hướng về phía trước.",
                "Gồng chặt cơ bụng, đẩy 2 quả tạ dứt khoát thẳng lên trên đầu nhưng không khóa khớp cùi chỏ.",
                "Từ từ hạ tạ về vị trí ban đầu trong khoảng 2-3 giây."
            ],
            commonMistakes: [
                "Ưỡn lưng quá mức làm áp lực dồn vào lưng dưới.",
                "Khóa khớp khuỷu tay đột ngột ở điểm cao nhất."
            ]
        ),
        ExerciseItem(
            name: "Cuốn tay trước với tạ đơn",
            englishName: "Dumbbell Bicep Curl",
            primaryMuscle: .arms,
            secondaryMuscles: ["Cơ cẳng tay"],
            equipment: .dumbbell,
            difficulty: .beginner,
            thumbnailImageName: "figure.arms.open",
            model3DRemoteURL: URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/retrotv/tv_retro.usdz")!,
            targetMeshNodeNames: ["biceps_brachii"],
            instructions: [
                "Đứng thẳng, mỗi tay cầm một quả tạ đơn duỗi thẳng bên hông.",
                "Giữ cố định cùi chỏ sát thân người, thở ra và gập cẳng tay nâng tạ lên.",
                "Siết chặt cơ tay trước tại điểm cao nhất trong 1 giây.",
                "Hạ tạ xuống từ từ có kiểm soát về điểm xuất phát."
            ],
            commonMistakes: [
                "Dùng đà vung người để nâng tạ.",
                "Dịch chuyển cùi chỏ về phía trước quá nhiều."
            ]
        ),
        ExerciseItem(
            name: "Hít đất",
            englishName: "Standard Push-Up",
            primaryMuscle: .chest,
            secondaryMuscles: ["Cơ tay sau", "Cơ vai trước", "Cơ bụng"],
            equipment: .bodyweight,
            difficulty: .beginner,
            thumbnailImageName: "figure.cooldown",
            model3DRemoteURL: URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/retrotv/tv_retro.usdz")!,
            targetMeshNodeNames: ["pectoralis_major", "triceps_brachii"],
            instructions: [
                "Bắt đầu ở tư thế Plank cao, hai tay đặt rộng hơn vai một chút, thân người tạo thành đường thẳng.",
                "Hít vào, siết mông và cơ bụng, hạ thấp ngực xuống cách sàn khoảng 2-3 cm.",
                "Thở ra và đẩy mạnh cơ ngực để trở lại tư thế bắt đầu."
            ],
            commonMistakes: [
                "Võng lưng hoặc nhô mông lên quá cao.",
                "Cổ bị gập hoặc ngửa quá mức."
            ]
        ),
        ExerciseItem(
            name: "Đạp đùi trên máy",
            englishName: "Leg Press Machine",
            primaryMuscle: .legs,
            secondaryMuscles: ["Cơ mông", "Cơ bắp chuối"],
            equipment: .machine,
            difficulty: .beginner,
            thumbnailImageName: "figure.run",
            model3DRemoteURL: URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/retrotv/tv_retro.usdz")!,
            targetMeshNodeNames: ["quadriceps", "gluteus_maximus"],
            instructions: [
                "Ngồi vào máy đạp đùi, lưng và mông áp sát đệm tựa.",
                "Đặt 2 bàn chân lên bàn đạp rộng bằng vai.",
                "Tháo chốt an toàn, từ từ gập gối hạ bàn đạp xuống cho đến khi góc gối đạt 90 độ.",
                "Dồn lực lòng bàn chân đẩy bàn đạp lên vị trí ban đầu (không khóa khớp gối)."
            ],
            commonMistakes: [
                "Khóa khớp gối thẳng đơ khi đẩy tạ lên cao.",
                "Nhấc mông ra khỏi ghế tựa lưng khi hạ tạ sâu."
            ]
        ),
        ExerciseItem(
            name: "Gập bụng trên thảm",
            englishName: "Floor Crunch",
            primaryMuscle: .core,
            secondaryMuscles: ["Cơ liên sườn"],
            equipment: .bodyweight,
            difficulty: .beginner,
            thumbnailImageName: "figure.mind.and.body",
            model3DRemoteURL: URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/retrotv/tv_retro.usdz")!,
            targetMeshNodeNames: ["rectus_abdominis"],
            instructions: [
                "Nằm ngửa trên thảm, co đầu gối và đặt bàn chân phẳng trên sàn.",
                "Đặt nhẹ hai bàn tay sau gáy hoặc chéo trước ngực.",
                "Thở ra, cuộn cơ bụng nâng vai lên khỏi sàn khoảng 10-15 cm.",
                "Hít vào và từ từ hạ lưng xuống trở lại thảm."
            ],
            commonMistakes: [
                "Dùng tay kéo gập cổ về phía trước gây đau đốt sống cổ.",
                "Nâng cả phần thắt lưng lên khỏi sàn thay vì chỉ cuộn bụng."
            ]
        )
    ]
}
