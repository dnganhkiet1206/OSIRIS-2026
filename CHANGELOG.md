# CHANGELOG

## [Unreleased]

### 2026-07-02 — M0-1: Project Bootstrap (M0-0 theo cách gọi của phiên làm việc)

- Khởi tạo cấu trúc dự án theo FOLDER_STRUCTURE.md v1.1; tài liệu chuyển vào `Docs/`, 18 file đặc tả gốc vào `Docs/archive/`.
- SwiftPM package `OsirisKit` (AD-30): target `OsirisCore` (6 thành phần: Kernel, Execution, Skills, Store, AIGateway, Tools) + `OsirisInfrastructure` (Storage, Logging, Security, Configuration, Events) + 2 test target.
- Kernel skeleton chạy đủ vòng đời 5 pha (Intake → Decide → Execute → Verify → Persist) với placeholder provider — end-to-end, không tốn chi phí AI.
- App shell SwiftUI (App/ + Presentation/Chat) + `project.yml` (XcodeGen) cho build iOS trên macOS.
- Config ngoài source: `preamble.md` (System Preamble < 400 token), models/routing/budgets/policies/features.json.
- Kiểm chứng trên Linux + Swift 6.0.3: build 0 error / 0 warning, 8/8 test pass.

### 2026-07-02 — Tài liệu kiến trúc v1.1

- Vòng review 2 (AD-22 → AD-29): Core 9 → 6 thành phần; một `Store` duy nhất (sửa dual-source-of-truth); Context Engine hợp nhất vào AI Gateway; Vision → Config artifact; Event Bus → Infrastructure; bỏ Networking layer; Skill schema tối thiểu; context tiering cho tài liệu.

### 2026-07-02 — Tài liệu kiến trúc v1.0

- Architecture Review 18 file đặc tả gốc (AD-01 → AD-21); ban hành 5 tài liệu nền tảng: PROJECT_BLUEPRINT, PROJECT_STATE, DEVELOPMENT_PLAN, FOLDER_STRUCTURE, SYSTEM_COMPONENTS.
