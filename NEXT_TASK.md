# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M4 — YouTube Module (Reference Implementation)** (DEVELOPMENT_PLAN.md §2/M4, AD-21/44)

## Current Task

**M4-1 — YouTube content pipeline v1: Idea → Script, composition xuyên namespace**

## Objective

Biến skeleton thành mảng nghiệp vụ dùng được đầu tiên và chứng minh nốt mảnh ghép mở rộng còn lại: **module composition tham chiếu skill built-in thuần bằng data** (compositionSteps = [SkillID] — đã là ID-based, về lý thuyết xuyên namespace miễn phí; M4-1 biến "lý thuyết" thành test).

## Phạm vi

1. **`youtube.script-generation`** — skill mới: script đầy đủ (không phải outline) từ một chủ đề/idea; template nghiệp vụ thật; keywords không giẫm `youtube.script-outline` (outline vs full script — cân nhắc keywords cẩn thận, test precedence).
2. **`youtube.idea-to-script`** — composition trong manifest: steps tham chiếu MIX (`youtube.idea-generation` → `youtube.script-generation`); nếu thấy giá trị hơn, một composition dùng `core.research-outline` làm bước 1 để chứng minh xuyên namespace core↔module. Trigger = hợp keywords bước con (cơ chế M1-3 nguyên trạng).
3. **Kiểm tra scaffold M3-3 trên module path:** bước cuối composition module nhận Executive Summary scaffold (test có sẵn pattern — thêm 1 assert là đủ).
4. **Không làm:** chưa Channel Analysis/SEO/Thumbnail/Shorts/Publishing (M4-2+); không UI module; không đổi contract trừ khi bằng chứng buộc (khi đó DỪNG hỏi user — contract vừa ship, đổi sớm là red flag).

## Files cần tạo/sửa

- `Modules/YouTube/YouTubeModule.swift` (thêm skills + composition vào manifest).
- `Tests/ModuleTests/` (mở rộng ModuleContractTests hoặc file mới cho pipeline).
- Docs cuối phiên (+AD mới CHỈ nếu có quyết định kiến trúc thật).

## Checklist

- [ ] Module vẫn thuần data — 0 dòng sửa Core, 0 dòng sửa contract.
- [ ] Composition xuyên namespace có test (steps resolve qua registry chung — Kernel không biết gì mới).
- [ ] Precedence outline vs full-script vs generic draft: deterministic, có test.
- [ ] Composition hỏng (thiếu step) degrade về plain AI — hành vi M1-3 giữ nguyên cho module.
- [ ] Zero regression 121 test cũ.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M4-2 — mảng nghiệp vụ kế: đề xuất SEO + Publishing Package, hoặc theo giá trị user).

## Definition of Done

Goal một câu kiểu "video ideas rồi viết script về X" chạy end-to-end qua composition module (test offline, captured prompts đúng thứ tự); xuyên namespace PROVEN; zero regression; contract không đổi.

## Estimated Complexity

Thấp–trung bình — chủ yếu data + test; rủi ro chính là keywords giẫm nhau.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0 (test offline).

## Risk

- Keyword overlap giữa 3 skill script-ish (outline/generation/draft) — precedence test bắt buộc, thà nhường generic còn hơn hijack sai.
- Cám dỗ thêm field mới vào contract (vd module-level template) — Năm Câu Hỏi + hỏi user trước.

## Những phần tuyệt đối không được sửa

- Core 6 thành phần; `ModuleManifest` contract (vừa ship M4-0).
- WriteGate/Reflection/ComplexityEstimate/scaffold (M3).
- Architecture Test rules (chỉ THÊM/siết); ADR cũ (AD-01…AD-44).
