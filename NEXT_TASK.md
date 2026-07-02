# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.

## Current Milestone

**M0 — Walking Skeleton** (DEVELOPMENT_PLAN.md §2)

## Current Task

**M0-2 — Store v0 bền vững + nạp Config thật vào CompositionRoot**

## Mục tiêu

1. `FileBackedStore`: implementation của protocol `Store` (Core/Store/Persistence/) dùng `Infrastructure.LocalStorage` (FileStorage) để persist ProjectState dưới dạng JSON — ProjectState sống sót qua app restart.
2. `CompositionRoot` đọc `Config/preamble.md` và `Config/routing.json` qua `ConfigurationLoader` thay vì hardcode chuỗi `"placeholder-local"`.

## Lý do cần làm

Tiêu chí hoàn thành M0 là "tắt app mở lại vẫn thấy ProjectState" — InMemoryStore hiện tại không đáp ứng. Config wiring xóa hai chỗ hardcode đang vi phạm Configuration First ở mức chấp nhận-tạm trong bootstrap.

## Các file cần tạo

- `Core/Store/Persistence/FileBackedStore.swift` — actor, JSON encode/decode từng record type qua LocalStorage; key theo convention `project-state/<projectID>.json`, `knowledge/<id>.json`, `working-context/<id>.json`.
- `Tests/CoreTests/FileBackedStoreTests.swift` — roundtrip qua thư mục tạm; test khôi phục sau khi tạo instance mới (mô phỏng app restart); test WorkingContext hết hạn không được trả về.

## Các file cần sửa

- `App/AppComposition/CompositionRoot.swift` — dùng FileBackedStore (Application Support directory) + ConfigurationLoader cho preamble/routing.
- `Docs/PROJECT_STATE.md`, `CHANGELOG.md`, `NEXT_TASK.md` (tạo bản mới cho M0-3) — cuối phiên.

## Dependency

- Đã có sẵn: `LocalStorage`/`FileStorage` (Infrastructure), `ConfigurationLoader`, các record type của Store, test hạ tầng.
- Không thêm dependency ngoài (SwiftData bị loại cho M0: JSON file qua LocalStorage là giải pháp nhỏ nhất đủ dùng, dễ thay thế sau).

## Checklist

- [ ] FileBackedStore pass toàn bộ StoreTests hiện có (chạy chung suite với InMemoryStore hoặc tách test dùng chung).
- [ ] Test "restart": ghi → tạo store instance mới cùng thư mục → đọc lại đúng.
- [ ] InMemoryStore giữ lại **chỉ** cho tests (ghi rõ trong doc comment).
- [ ] CompositionRoot không còn literal `"placeholder-local"` và preamble hardcode.
- [ ] `swift build` 0 error / 0 warning; `swift test` pass toàn bộ.
- [ ] Không tái tạo component bị cấm (SYSTEM_COMPONENTS.md §6).
- [ ] Self Review + Architecture Review + cập nhật docs + NEXT_TASK mới.

## Definition of Done

ProjectState roundtrip qua đĩa được chứng minh bằng test; Config là nguồn duy nhất cho preamble/model ID; build sạch; tài liệu cập nhật; NEXT_TASK cho M0-3 đã tạo.

## Estimated Complexity

Thấp — ~2 file mới nhỏ, 1 file sửa; không đụng contract nào.

## Estimated AI Cost

0 token runtime (chưa có AI call thật). Chi phí dev session: nhỏ — chỉ cần nạp PROJECT_STATE.md + NEXT_TASK.md + 3 file Store hiện có.

## Các rủi ro

- JSON schema của ProjectState sẽ tiến hóa → migration. Chấp nhận ở M0 (chưa có dữ liệu thật); ghi nhận khi schema đổi lần đầu.
- Đường dẫn Application Support khác nhau giữa iOS/macOS/Linux test — dùng URL inject qua init, không hardcode.

## Những phần tuyệt đối không được sửa

- Protocol `Store` (contract đã chốt — thêm implementation, không đổi interface).
- 6 thành phần Core, cấu trúc thư mục, Package.swift targets.
- Danh sách component bị cấm (SYSTEM_COMPONENTS.md §6) — không Context Engine, không Memory/State Store riêng, không Networking layer.
- `Docs/PROJECT_BLUEPRINT.md` (trừ khi có AD mới được duyệt).
