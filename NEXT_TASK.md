# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau. Lưu ý: M4 là milestone module ĐẦU TIÊN chạy trên nền thật — giá trị runbook tăng thêm một bậc.

## Current Milestone

**M4 — YouTube Module (Reference Implementation)** (DEVELOPMENT_PLAN.md §2/M4, AD-21) — CHỜ USER XÁC NHẬN MỞ

## Current Task

**M4-0 — Module Contract v1 + YouTube Module skeleton (walking skeleton của M4)**

## Objective

Trước khi viết module nghiệp vụ đầu tiên phải TỒN TẠI định nghĩa "module là gì" — và định nghĩa đó phải mỏng: **module = gói DATA (skills + templates + manifest), không phải gói CODE**. M4-0 chốt Module contract v1 (Module Manifest — registry thứ hai được phép theo AD-17) và dựng YouTube module skeleton với 1–2 skill nghiệp vụ thật (vd `youtube.idea-generation`, `youtube.script-outline`) chứng minh: **thêm module = thêm data, 0 dòng sửa Core** (chuẩn AD-31 đã đặt cho provider).

## Phạm vi

1. **Module Manifest schema tối thiểu** (kiểu AD-28: bắt buộc ít nhất có thể — id/version/purpose/skills; mọi field khác chờ bằng chứng): module khai báo skills nó đóng góp; đọc từ đâu (bundle folder `Modules/YouTube/`? code-authored như GenericSkills?) — tự phản biện, chọn phương án ÍT máy móc nhất đủ cho 1 module; KHÔNG dynamic loading/reflection/script engine.
2. **Đăng ký qua Skill Registry hiện có:** module skills vào CHUNG `InMemorySkillRegistry` tại composition root — không ModuleRegistry chứa logic, manifest chỉ là data descriptor (AD-17: đúng 2 registry, cái thứ hai là MANIFEST, không phải engine).
3. **1–2 YouTube skill thuần data** với promptTemplate + triggerKeywords nghiệp vụ thật; kiểm tra không giẫm keywords generic skills (tie-break test).
4. **EventBus deadline M4 bắt đầu đếm:** module có subscribe events không? Ghi nhận ngay từ M4-0 — bằng chứng cho quyết định giữ/xóa ở M4 review.
5. **Không làm:** không đủ 9 mảng nghiệp vụ YouTube (đó là cả M4); không UI module riêng; không Module lifecycle/sandbox/permission system (chưa có bằng chứng cần).

## Files cần tạo

- Module manifest + YouTube skills (vị trí theo quyết định (1) — cập nhật FOLDER_STRUCTURE nếu tạo thư mục mới).
- `Tests/CoreTests/ModuleContractTests.swift` (hoặc tên phù hợp): module skills được match đúng, không phá generic skills, thêm module không sửa Core (bằng chứng kiểu AD-31: diff Core = 0).

## Checklist

- [ ] Module = data; 0 dòng thay đổi trong Core/ (trừ khi review chứng minh thiếu seam — khi đó DỪNG, hỏi user trước).
- [ ] Không component mới trong Core 6; không registry logic mới.
- [ ] Business skill KHÔNG vào `Core/Skills/BuiltIn/` (GenericSkills chỉ chứa domain-neutral — ranh giới đã ghi trong file đó).
- [ ] Tie-break/precedence với generic skills có test.
- [ ] Zero regression 114 test cũ.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M4-1 — mảng nghiệp vụ YouTube tiếp theo).

## Definition of Done

Module contract v1 thành văn (BLUEPRINT/AD mới); YouTube module skeleton với ≥1 skill nghiệp vụ chạy end-to-end qua vòng đời Kernel hiện có (test offline); chứng minh "thêm module không sửa Core"; zero regression.

## Estimated Complexity

Trung bình — quyết định contract là phần khó, code là phần dễ.

## Estimated AI Cost

Dev session: trung bình. Runtime: 0 (test offline với provider giả).

## Risk

- Module contract phình thành plugin system (lifecycle/permissions/sandbox) — v1 chỉ cần manifest data + skills; mỗi thứ thêm phải qua Năm Câu Hỏi.
- Keywords nghiệp vụ giẫm generic skills — test precedence bắt buộc.

## Những phần tuyệt đối không được sửa

- Core 6 thành phần (mục tiêu của task là chứng minh KHÔNG cần sửa chúng).
- WriteGate/Reflection/ComplexityEstimate/scaffold pipeline (M3 vừa chốt).
- Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-43).
