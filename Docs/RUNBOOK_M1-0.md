# RUNBOOK M1-0 — Xác minh trên Mac & Thu Baseline thật

> Dành cho user tự chạy (môi trường dev AI không có macOS/API key). Sau khi hoàn thành, dán kết quả lại cho phiên dev kế tiếp để điền vào PROJECT_STATE §4b. **Không bước nào ở đây thay đổi code.**

## Phần A — Build & chạy trên Mac (~10 phút)

1. Cài công cụ (một lần):
   ```bash
   brew install xcodegen
   ```
2. Tại thư mục repo:
   ```bash
   swift test          # kỳ vọng: toàn bộ test PASS (số lượng tăng theo milestone; xác nhận package trên macOS)
   xcodegen generate   # sinh OSIRIS.xcodeproj từ project.yml
   open OSIRIS.xcodeproj
   ```
3. Chọn scheme **Osiris** → một iPhone Simulator (iOS 17+) → **⌘R**.
4. Nếu có lỗi compile trong `App/` hoặc `Presentation/` (vùng duy nhất chưa qua compiler): copy nguyên văn lỗi, dán cho phiên dev kế tiếp. KHÔNG tự sửa kiến trúc.

**Kiểm tra bằng mắt (offline mode — chưa cần key):**
- [ ] App mở thẳng vào Chat, sidebar có Chat + Settings.
- [ ] Gõ một goal → thấy status line ("Understanding…", "Planning…"…) → nhận kết quả `[placeholder:…]`.
- [ ] Gõ lại **đúng goal đó** → kết quả trả về gần như tức thì (reuse, 0 AI call).
- [ ] Tắt app, mở lại → gõ lại goal cũ vẫn trả tức thì (ProjectState sống sót restart).
- [ ] Gõ goal rỗng/khoảng trắng → nhận câu hỏi thân thiện, không crash.

## Phần B — Kết nối provider thật (~5 phút)

1. Vào **Settings** trong app → dán Anthropic API key (`sk-ant-…`) → **Save Key** → thấy "Key saved securely".
2. Tắt hẳn app và mở lại (provider chọn lúc khởi động).
3. Settings hiển thị **Status: Connected**.

## Phần C — Smoke test & thu baseline (AD-15) (~5 phút, tốn vài trăm token ≈ dưới $0.01)

1. Mở **Xcode console** (khu vực log khi chạy app).
2. Gõ lần lượt 3 goal **mới, khác nhau** (ví dụ: "Summarize the benefits of daily planning", "Draft a tweet about focus", "List 3 ideas for a productivity video").
3. Sau mỗi goal, tìm dòng log `ai.request` — copy nguyên văn. Mỗi dòng chứa:
   `model, latencySeconds, estimatedTokensIn, actualTokensIn, actualTokensOut, costUSD, cacheHit, retryCount, succeeded`
4. Gõ lại **goal số 1 nguyên văn** → dòng log không xuất hiện thêm `ai.request` mới (reuse) HOẶC xuất hiện với `cacheHit=true` — ghi nhận trường hợp nào xảy ra.
5. Dán 3–4 dòng log đó cho phiên dev kế tiếp.

**Baseline sẽ được ghi vào PROJECT_STATE §4b dạng:**

| Chỉ số | Giá trị |
|---|---|
| Tokens in/out trung bình (goal đơn giản, preamble ~150 token) | … |
| Latency trung bình (end-to-end provider) | … s |
| Cost/request | $… |
| Reuse lần 2 | 0 AI call / cache-hit |

## Phần D — Nếu có sự cố

- **401 khi gọi:** key sai → Settings → Remove Key → nhập lại.
- **App chạy nhưng vẫn `[placeholder:…]`:** chưa restart sau khi lưu key, hoặc key rỗng.
- **Build fail:** dán lỗi nguyên văn cho phiên dev kế tiếp — vùng App/Presentation là nơi duy nhất chưa qua compiler, đã dự phòng trong kế hoạch.
- Key KHÔNG bao giờ xuất hiện trong log — nếu bạn thấy key trong bất kỳ log nào, dừng ngay và báo (đó là lỗi bảo mật nghiêm trọng, hiện không có đường code nào in key).
