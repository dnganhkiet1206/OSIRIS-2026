# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M4 — YouTube Module (Reference Implementation)** (DEVELOPMENT_PLAN.md §2/M4, AD-21/44)

## Current Task

**M4-2 — YouTube: SEO + Publishing Package (2 mảng thuần prompt-data)**

## Objective

Phủ tiếp 2 capability của M4 bằng đúng khuôn M4-1 — chứng minh khuôn mẫu LẶP LẠI ĐƯỢC (điều kiện để mọi module M5 copy): `youtube.seo-package` (title options / description / tags / hashtags từ một video topic hoặc script) và `youtube.publishing-package` (composition tổng hợp: script → SEO → checklist đăng — cân nhắc steps từ skill có sẵn). Zero Core, zero contract — nếu cần gì hơn data, DỪNG hỏi user.

## Phạm vi

1. **`youtube.seo-package`** — skill prompt-data: output có cấu trúc (titles/description/tags); keywords: "seo", "title", "tags", "mô tả video"… — kiểm tra không giẫm generic + skill youtube hiện có (precedence test).
2. **`youtube.publishing-package`** — composition ≤3 bước từ skill CÓ SẴN (vd script-generation → seo-package; hoặc thêm checklist prompt-skill nhỏ nếu cần bước 3 — Năm Câu Hỏi trước khi thêm); union keywords tuyển chọn theo guideline M4-1.
3. **Đường AI Cost:** mỗi composition thêm bước = thêm AI call — ghi rõ trong docs skill purpose để user hiểu chi phí; không auto-chain quá 3 bước (BLUEPRINT: composition <5, dưới 3 ưu tiên direct).
4. **Không làm:** Channel Analysis / Thumbnail / Shorts (M4-3+); đặc biệt Channel Analysis cần DỮ LIỆU THẬT từ kênh — sẽ đặt câu hỏi tool-contribution-channel cho contract, để dành đến khi đó với bằng chứng đầy đủ.

## Files cần tạo/sửa

- `Modules/YouTube/YouTubeModule.swift` (skills + manifest version bump).
- `Tests/ModuleTests/` (precedence + pipeline tests theo khuôn M4-1).
- Docs cuối phiên.

## Checklist

- [ ] 0 dòng sửa Core, 0 dòng sửa contract, 0 dòng sửa matcher.
- [ ] Precedence có test cho mọi cặp keywords giao nhau.
- [ ] Composition mới ≤3 bước, union tuyển chọn, có test thứ tự + degrade.
- [ ] Zero regression 127 test cũ.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M4-3 — đề xuất: Channel Analysis + câu hỏi tool-channel, HOẶC M4 review nếu đủ bằng chứng khuôn mẫu).

## Definition of Done

2 mảng mới chạy end-to-end offline qua lifecycle nguyên trạng; khuôn M4-1 lặp lại không phát sinh nhu cầu sửa gì ngoài data; zero regression.

## Estimated Complexity

Thấp — data + test theo khuôn có sẵn; rủi ro chính vẫn là keyword overlap.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0 (test offline).

## Risk

- Keyword giao nhau tăng theo số skill (n²) — mỗi skill mới phải rà bảng keywords toàn registry; nếu bắt đầu đau, đó là BẰNG CHỨNG cho matcher nâng cấp (ghi nhận, không tự ý làm).
- Composition dài để "cho đủ" — mỗi bước phải trả lời được nó thêm giá trị gì.

## Những phần tuyệt đối không được sửa

- Core 6 thành phần; `ModuleManifest` contract; matcher `selectByKeywords`.
- WriteGate/Reflection/ComplexityEstimate/scaffold (M3).
- Architecture Test rules (chỉ THÊM/siết); ADR cũ (AD-01…AD-44).
