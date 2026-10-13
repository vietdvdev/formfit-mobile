#!/bin/bash
set -e

echo "=== FormFit iOS Setup Script ==="

# Check if xcodegen is installed
if command -v xcodegen &> /dev/null; then
    echo "✓ Tìm thấy xcodegen trên hệ thống."
    xcodegen generate
else
    echo "⚙ xcodegen chưa có sẵn. Đang tải bản thực thi xcodegen..."
    curl -sL -o xcodegen.zip https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip
    rm -rf .xcodegen_temp
    unzip -q xcodegen.zip -d .xcodegen_temp
    rm -f xcodegen.zip
    
    echo "⚙ Đang tạo file FormFit.xcodeproj..."
    ./.xcodegen_temp/bin/xcodegen generate
    echo "✓ Đã tạo thành công FormFit.xcodeproj!"
fi

echo "🚀 Đang mở FormFit.xcodeproj trong Xcode..."
open FormFit.xcodeproj
echo "=== HOÀN TẤT: Hãy chọn Simulator (ví dụ iPhone 15 Pro) và bấm Cmd + R ==="
