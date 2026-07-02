# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.

## Current Milestone

**M0 — Walking Skeleton** (DEVELOPMENT_PLAN.md §2) — task cuối cùng.

## Current Task

**M0-6 — M0 Closeout: provider thật đầu tiên + token baseline + M0 review tổng**

## Objective

Core M0 đã hoàn thiện và ổn định → AD-31 cho phép integration đầu tiên. Mục tiêu: một AI call thật đi hết đường `Kernel → AI Gateway → AnthropicProvider`, usage thật được đo (token baseline đầu tiên của dự án — AD-15), app vẫn chạy được hoàn toàn khi chưa có API key, và M0 được nghiệm thu theo Definition of Done.

## Phạm vi

1. **`AnthropicProvider`** (`Core/AIGateway/Providers/`): adapter Messages API bằng URLSession thuần (AD-27); pin `anthropic-version`; parse text + usage thật (input/output tokens) vào `ProviderResponse`; error map rõ ràng (401/429/5xx → error mô tả được, KHÔNG chứa API key). Adapter chỉ làm một việc — mọi thứ khác (budget/cache/retry/metrics) đã thuộc Gateway.
2. **`KeychainSecretsVault`** (`App/AppComposition/`): implement `SecretsVault` bằng Keychain Services (Xcode-only; giữ nhỏ nhất).
3. **CompositionRoot graceful:** có key trong vault → AnthropicProvider; chưa có → PlaceholderAIProvider. App KHÔNG BAO GIỜ crash vì thiếu key.
4. **Config:** thêm model Anthropic thật (tier light, giá thật) vào `models.json` + `routing.json`.
5. **Token baseline:** chạy 1 smoke test thủ công có key (trên Mac hoặc qua swift run CLI nhỏ? — chỉ khi khả thi) và ghi số liệu đầu tiên vào PROJECT_STATE. Nếu môi trường không có key/Mac: ghi rõ baseline pending, KHÔNG giả số liệu.
6. **M0 review tổng** theo Definition of Done (DEVELOPMENT_PLAN §3): kiểm từng tiêu chí M0, ghi kết quả vào PROJECT_STATE; xác minh build iOS/simulator trên Mac (nếu không có Mac trong phiên: ghi pending — đây là mục duy nhất được phép pending).

## Files cần tạo

- `Core/AIGateway/Providers/AnthropicProvider.swift`
- `App/AppComposition/KeychainSecretsVault.swift`
- `Tests/CoreTests/AnthropicProviderTests.swift` — parse fixture JSON (KHÔNG network trong test); map lỗi HTTP; usage đúng.

## Files cần sửa

- `App/AppComposition/CompositionRoot.swift` — chọn provider theo key; đọc key qua SecretsVault.
- `Config/models.json`, `Config/routing.json` — model thật + placeholder fallback.
- `Docs/PROJECT_STATE.md`, `CHANGELOG.md`, `NEXT_TASK.md` (bản mới — mở M1 hoặc phần còn thiếu của M0 nếu review fail).

## Dependency

- Toàn bộ Gateway pipeline (M0-3) và graceful composition đã sẵn. Không SDK ngoài — URLSession thuần. Test dùng fixture; smoke test thật là bước thủ công có kiểm soát (Approval contract: chi tiêu nhỏ, có chủ đích).

## Checklist

- [ ] Test parse/error của AnthropicProvider chạy offline, không network.
- [ ] API key chỉ qua SecretsVault; arch-grep nhanh: không có chuỗi `sk-` / key literal trong repo; key không xuất hiện trong log/error message.
- [ ] App chạy đầy đủ không key (Placeholder fallback) — không crash, không lỗi user-facing khó hiểu.
- [ ] Không hardcode model ID trong code — chỉ từ Config.
- [ ] Arch tests giữ nguyên pass (AnthropicProvider nằm trong Core/AIGateway — đúng vùng được phép).
- [ ] `swift build` 0 error / 0 warning; toàn bộ test pass.
- [ ] M0 Definition of Done: từng mục được đánh giá và ghi lại trung thực (pass / pending kèm lý do).
- [ ] Self Review + Architecture Review + docs + NEXT_TASK mới.

## Definition of Done

AnthropicProvider hoạt động sau Gateway với usage thật được log; app không key vẫn dùng được; token baseline được ghi (hoặc pending có lý do rõ); M0 closeout report nằm trong PROJECT_STATE; NEXT_TASK kế tiếp đã tạo.

## Estimated Complexity

Trung bình — adapter mạng + DTO + error mapping + Keychain nhỏ.

## Estimated AI Cost

Dev session: nhỏ. Runtime: lần đầu có chi phí thật, chỉ khi có key và chỉ trong smoke test thủ công (vài trăm token).

## Risk

- Test gọi mạng thật = flaky + tốn tiền → cấm trong test suite; fixture only.
- Keychain code không compile trên Linux → nằm ở App/ (Xcode-only), lỗi compile lộ ở lần build Mac đầu — giữ file nhỏ nhất.
- API schema đổi theo version → pin `anthropic-version` header, ghi chú nguồn trong doc comment.

## Những phần tuyệt đối không được sửa

- `DefaultAIGateway` pipeline (adapter cắm vào, Gateway không đổi — đó chính là phép thử của AD-31).
- `ChatService`/`TaskUpdate` contract (UI không được biết provider mới xuất hiện).
- Kernel, Execution, Store, Skill Registry.
- Architecture Test rules (chỉ được THÊM).
- ADR cũ (AD-01…AD-35) — chỉ thêm ADR mới nếu có quyết định mới.
