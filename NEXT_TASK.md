# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M2 — User Experience** (DEVELOPMENT_PLAN.md §2/M2) — task áp chót; sau đó M2-6 = M2 Review.

## Current Task

**M2-5 — Advanced Mode gate + Accessibility pass**

## Objective

Hoàn tất hai mục còn lại của phạm vi M2: (1) **Advanced Mode** — ẩn mặc định, bật qua Settings, expose các panel dev tối thiểu từ dữ liệu ĐÃ CÓ (không xây viewer mới phức tạp); (2) **Accessibility pass** — Dynamic Type/labels/contrast ở mức code-level cho toàn bộ UI hiện có (xác minh mắt thường thuộc Mac runbook).

## Phạm vi

1. **Advanced Mode toggle:** Settings thêm switch "Advanced Mode" — trạng thái lưu qua... `features.json` là bundle read-only trên iOS! → runtime setting: UserDefaults? UserDefaults là storage ngoài LocalStorage — vi phạm "chỉ Store persist"? UserDefaults cho UI preference thuần (không phải dữ liệu platform) — **cân nhắc trong phiên**: (a) UserDefaults cho UI-pref (đơn giản, chuẩn iOS; ghi rõ ranh giới: UI preferences ≠ platform data — cần AD nhỏ); (b) đổi qua Store WorkingContext — sai ngữ nghĩa (TTL). Nghiêng (a) + AD-40 định nghĩa ranh giới "UI preferences sống ở UserDefaults, platform data sống ở Store".
2. **Advanced panels (chỉ khi bật):** sidebar section Advanced gồm: **Session Metrics** (tái dùng DashboardSnapshot.usage — chi tiết hơn: per-request? KHÔNG — chỉ tổng, thêm contextSnippets/retry đã có trong metrics? giữ tổng session), **Skills** (danh sách skill từ registry — cần closure port mới `listSkills` qua Application? Kernel giữ registry... registry inject ở composition — composition có sẵn `InMemorySkillRegistry` instance → port closure `skills()` trả `[SkillInfo]` DTO), **About/Health** (version, test count?, provider mode). Giữ mỗi panel là read-only list đơn giản.
3. **Accessibility:** accessibilityLabel cho các nút icon-only (send, new project, deliverable rows), Dynamic Type không bị chặn (không fixed font size — rà soát), contrast dùng semantic colors (đã dùng). Diff nhỏ, rải rác các view.
4. **Không làm:** Memory/Log viewer đầy đủ (cần data pipeline riêng — để sau khi có nhu cầu thật); không đổi Core.

## Files cần tạo

- `Presentation/Advanced/AdvancedView.swift` (+ panel con nếu cần, giữ nhỏ), `Tests/ApplicationTests/SkillListingTests.swift` (nếu thêm port skills).

## Files cần sửa

- `Application/ProviderSettings.swift` hoặc file port phù hợp (+advancedMode get/set closure, +skills list closure), `App/AppComposition/CompositionRoot.swift`, `Presentation/Settings/SettingsView.swift` (toggle), `Presentation/Chat/ChatView.swift` (section Advanced khi bật), các view (accessibility labels).
- Docs cuối phiên (+AD-40 nếu chốt UserDefaults cho UI-pref).

## Checklist

- [ ] Advanced Mode ẩn mặc định; tắt = sidebar sạch như cũ.
- [ ] Ranh giới UI-pref vs platform-data ghi thành AD (không lặng lẽ thêm nguồn persist).
- [ ] Panel = read-only, không hành động phá hoại.
- [ ] Mọi nút icon-only có accessibilityLabel.
- [ ] `swift build` 0 warning; toàn bộ test pass offline.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M2-6 — M2 Review: DoD, tên port ProjectDirectory, InMemorySecretsVault, tag M2).

## Definition of Done

Advanced Mode bật/tắt hoạt động với ≥2 panel read-only từ dữ liệu có sẵn; accessibility labels phủ các nút icon-only; zero regression.

## Estimated Complexity

Thấp–Trung bình.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0.

## Risk

- Advanced panels creep thành dev-tool platform — giữ read-only list, không tương tác.
- UserDefaults mở tiền lệ persist tùy tiện — AD-40 phải định nghĩa ranh giới chặt.

## Những phần tuyệt đối không được sửa

- Core (không lý do gì đụng); Gateway/Kernel/Store.
- Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-39).
