# NEXT_TASK.md

> **TRẠNG THÁI: CHỜ XÁC NHẬN CỦA USER.** M0 đã nghiệm thu (PROJECT_STATE §4b). Task dưới đây là ĐỀ XUẤT cho phiên đầu tiên của M1 — không tự ý bắt đầu.

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.

## Current Milestone

**M1 — Core Runtime** (đề xuất mở; DEVELOPMENT_PLAN.md §2)

## Current Task (đề xuất)

**M1-0 — Verification & Baseline: trả nốt 2 mục pending của M0 trước khi xây tính năng M1**

## Objective

Đóng hai mục PENDING của M0 closeout để mọi tính năng M1 xây trên nền đã xác minh thật:
1. **Mac verification:** `xcodegen generate` → build iOS simulator → chạy app thật: gõ goal → events → deliverable → restart giữ ProjectState. Sửa mọi lỗi compile của App/Presentation (vùng chưa qua compiler).
2. **API key entry tối thiểu:** một màn Settings nhỏ (1 SecureField → KeychainSecretsVault qua Application layer — thêm method `setAPIKey` vào ChatService hoặc một SettingsService mỏng; giữ đúng AD-35: Presentation không chạm Infrastructure).
3. **Token baseline thật (AD-15):** 1–3 smoke call có kiểm soát qua claude-haiku; ghi vào PROJECT_STATE: tokens in/out, latency, cost, cache-hit lần 2. Đây là baseline mọi tối ưu M3/M7 so sánh về sau.

## Lý do

Định nghĩa Done của M0 có 2 mục chỉ hoàn thành được trên Mac + có key. Kéo dài sang M1 mà không đóng sẽ tích lũy rủi ro compile UI và mọi quyết định token thiếu số liệu gốc.

## Files cần tạo

- `Presentation/Settings/SettingsView.swift` — tối giản: nhập/xóa API key, trạng thái provider hiện tại ("Offline mode" / "Connected").
- (Application) API mỏng cho Settings — cân nhắc `SettingsService` riêng chỉ khi ChatService bắt đầu gánh 2 vai; nếu chỉ 1 method thì thêm vào ChatService, không tạo service mới (Năm Câu Hỏi).

## Files cần sửa

- `App/AppComposition/CompositionRoot.swift` — expose vault cho Application API; chọn lại provider sau khi key đổi (restart-based là đủ cho v0 — ghi rõ trong UI).
- `Presentation/Chat/ChatView.swift` — sidebar thêm mục Settings.
- `Docs/PROJECT_STATE.md` (điền baseline), `CHANGELOG.md`, `NEXT_TASK.md` (M1-1: Skill Registry đầy đủ + 3–5 skill tổng quát).

## Dependency

- Cần: máy Mac có Xcode + XcodeGen; API key Anthropic của user (chi tiêu nhỏ có chủ đích — Approval contract).
- Nếu phiên chạy trong môi trường không có Mac: chỉ làm phần 2 (code Settings) + để 1 và 3 thành hướng dẫn từng bước cho user tự chạy, KHÔNG giả số liệu.

## Checklist

- [ ] App build + chạy trên simulator; luồng goal → deliverable hoạt động bằng mắt thường.
- [ ] Key nhập qua Settings vào Keychain; không bao giờ hiển thị lại plain text; không vào log.
- [ ] Baseline ghi vào PROJECT_STATE với số thật (hoặc đánh dấu pending kèm hướng dẫn).
- [ ] Arch tests giữ nguyên pass; không sửa Core (trừ khi Mac build lộ lỗi compile — sửa lỗi được phép, không đổi thiết kế).
- [ ] Self/Architecture/Quality Review + docs + NEXT_TASK mới.

## Definition of Done

Hai mục pending của M0 đóng (hoặc có hướng dẫn thực thi rõ nếu môi trường thiếu Mac/key); baseline nằm trong PROJECT_STATE; app dùng được thật trên simulator.

## Estimated Complexity

Thấp — chủ yếu wiring + xác minh; rủi ro là lỗi compile SwiftUI tồn đọng.

## Estimated AI Cost

Dev session: nhỏ. Runtime: vài trăm token cho smoke test (chỉ khi user cung cấp key).

## Risk

- Lỗi compile App/Presentation tích tụ từ M0-1 → M0-6 lộ ra cùng lúc ở lần build Mac đầu — dự phòng thời gian sửa.
- Đổi provider cần restart app (composition tĩnh) — chấp nhận ở v0, ghi trong UI; hot-swap chỉ làm khi có nhu cầu thật.

## Những phần tuyệt đối không được sửa

- Toàn bộ thiết kế Core/Gateway/Store/Kernel (chỉ fix lỗi compile nếu Mac build lộ ra, không đổi thiết kế).
- Architecture Test rules (chỉ được THÊM).
- ADR cũ (AD-01…AD-35).
- Không bắt đầu Skill Registry/tính năng M1 nào khác trong M1-0.
