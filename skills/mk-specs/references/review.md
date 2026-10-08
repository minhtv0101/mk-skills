# Tự soát spec (mode `review`)

Agent đọc lại spec **mình vừa viết** trước khi đưa người duyệt: tự tìm mâu thuẫn, thiếu sót, phần thừa, chỗ đoán ý; sửa lỗi của chính mình, hỏi người dùng những điểm cần quyết. Ba nhịp: soát → hỏi có phương án → ghi câu trả lời. Mọi bước nằm trong file này; không cần skill hay công cụ nào khác ngoài `python3`.

**Khi nào chạy**
- Tự động, ngay sau khi viết xong: proposal ở mode `change` (trước commit 1), BR/UC đầu tiên hoặc baseline ở mode `init`.
- Khi người dùng yêu cầu: "soát spec", "review proposal", "kiểm lại spec vừa viết".

**Không phải duyệt.** Tự soát không thay review hai phía (workflow-change.md §2): không điền `Người duyệt kỹ thuật`/`Người duyệt nghiệp vụ`, không đổi Status sang `approved`.

## 1. Xác định đối tượng

1. Người dùng chỉ file/thư mục → dùng đúng file đó.
2. Không chỉ → artifact vừa viết trong phiên này; không có → proposal mới nhất trong `specs/changes/` có Status `draft`/`reviewing`.
3. Vẫn không xác định được → hỏi người dùng, dừng.

Đọc kèm: lời yêu cầu gốc của người dùng (nguyên văn), BR + UC + ADR + `entities.md` liên quan, `open-issues.md`.

## 2. Kiểm bằng máy

```bash
python3 .claude/skills/mk-specs/scripts/audit.py     # mục thiếu, chữ kỹ thuật trong flow/AC
python3 .claude/skills/mk-specs/scripts/verify.py    # link, thẻ UC/AC, test được trích
```

Chỉ xét dòng thuộc đối tượng đang soát; lỗi cũ ở file khác ghi một dòng "đã có từ trước", không sửa (cùng lý do ở nguyên tắc "Sửa đúng chỗ" trong SKILL.md).

## 3. Tự soát theo năm nhóm

Đọc từng câu của đối tượng, hỏi:

| Nhóm | Câu hỏi kiểm |
|---|---|
| **Đúng ý** | Mỗi AC/flow/entity truy được về lời yêu cầu hoặc BR không? Có chỗ nào mình chọn một cách hiểu trong nhiều cách mà không hỏi? Giá trị nào (thời hạn, ngưỡng, phí, quyền) mình tự đặt? |
| **Mâu thuẫn** | AC nào chọi AC khác (cùng Given, Then khác)? AC trái Out of Scope của BR, ADR đang `accepted`, bất biến trong `entities.md`, UC khác? Con số có khớp giữa Vì sao, AC, entity không? `ADDED AC-n` có trùng ID đã có? `MODIFIED`/`DEPRECATED` có trỏ tới AC có thật? |
| **Thiếu sót** | Thiếu Actor/Trigger? Biên đã rõ chưa (đúng 15 phút thì sao)? Hệ quả phủ định ("KHÔNG tạo đơn") khi cần? Exception đã có quyết định xử lý? Dữ liệu cũ khi đổi luật? Mục open-issues nào thay đổi này đóng được mà chưa ghi `Đóng`? Luật tiền/quyền/bảo mật nào chưa có người quyết? |
| **Thừa** | UC/AC/entity/ADR nào không ai yêu cầu? Cấu hình hoá, "để sau này mở rộng", exception cho tình huống không xảy ra được? Đoạn nào cắt đi người duyệt vẫn hiểu đủ? Proposal có quá một màn hình đọc? |
| **Kiểm được** | Given có dữ liệu cụ thể? Then đo được, không chứa "nhanh", "hợp lý", "thân thiện", "v.v."? Flow/AC đọc được với người không biết code? |

Xong các AC, đọc lại một lượt từ góc người duyệt nghiệp vụ: "ký vào đây thì mình đang đồng ý điều gì?" — câu trả lời phải trùng ý người yêu cầu.

## 4. Phân loại phát hiện

| Loại | Ví dụ | Làm gì |
|---|---|---|
| **Lỗi của mình, một cách sửa hiển nhiên, không đổi nghĩa nghiệp vụ** | trùng ID AC, sót placeholder `<…>`, link hỏng, chữ kỹ thuật trong AC, thiếu dòng `- Tests:`, AC thừa mình tự thêm | Sửa ngay, ghi vào danh sách "Đã tự sửa" |
| **Cần người quyết** | nhiều cách hiểu, giá trị tự đặt, mâu thuẫn với BR/ADR, thiếu luật cho một nhánh, mọi thứ dính tiền/quyền/bảo mật | Thành câu hỏi (§5) |
| **Ngoài phạm vi** | lỗi ở UC không liên quan, ý tưởng mở rộng | Ghi một dòng trong báo cáo, không sửa, không hỏi |

Bỏ AC thừa do chính mình thêm là "tự sửa"; bỏ thứ người dùng đã nêu là "cần người quyết".

## 5. Hỏi người dùng

- Chỉ hỏi điểm quyết định thật — câu trả lời làm đổi AC, flow, entity hoặc phạm vi. Không hỏi điều repo, spec, code trả lời được; không bày lựa chọn giả.
- Mỗi câu: bối cảnh một dòng (trích chỗ trong spec), 2–4 phương án cụ thể kèm hệ quả, đánh dấu phương án đề xuất và lý do. Agent có sẵn công cụ hỏi người dùng thì có thể dùng (tối đa 4 câu một lượt); không có thì liệt kê đánh số trong chat như ví dụ dưới rồi dừng chờ — cả hai cách đều đủ.
- Mặc định 3–8 câu; spec đơn giản thì ít hơn, kể cả 0. Ưu tiên câu làm đổi nhiều AC nhất.
- Tiền, quyền truy cập, bảo mật, pháp lý: được đề xuất nhưng **không** tự áp phương án đề xuất khi người dùng chưa chọn (cổng cứng 2).

Ví dụ:

```
Nhóm: Đúng ý
Câu hỏi: Proposal ghi mã QR hết hạn sau 15 phút. Đơn đã quét mã nhưng tiền về ở phút 16 thì sao?
1. Vẫn nhận tiền, ghi nhận đơn (Đề xuất — khách đã trả, từ chối gây khiếu nại)
2. Tự hoàn tiền, huỷ đơn
3. Giữ tiền, chuyển nhân viên xử lý tay
```

## 6. Ghi lại

1. Câu trả lời làm đổi spec → sửa delta trong proposal (hoặc BR/UC ở mode `init`). Người dùng chưa trả lời / "để sau" → `[OPEN]` có ngữ cảnh, không đoán.
2. Proposal: điền mục `## Tự soát` (mẫu `proposal.md`):

```markdown
## Tự soát
- Ngày: YYYY-MM-DD · audit.py: <kết quả> · verify.py: <kết quả>
- Đã tự sửa: <mỗi ý một cụm ngắn, hoặc —>
- Đã hỏi (N câu): <câu hỏi ngắn> → <lựa chọn, ai trả lời>
- Còn mở: <[OPEN] mới, hoặc —>
```

3. Mode `init`: không có proposal → không thêm mục mới vào BR/UC; quyết định đi thẳng vào nội dung, phần chưa rõ thành `[OPEN]`, tóm tắt trong câu trả lời.

## 7. Báo kết quả

Một khối ngắn: đối tượng đã soát · lệnh đã chạy + kết quả thật · số lỗi đã tự sửa · số câu đã hỏi và quyết định · `[OPEN]` còn lại · kết luận: **sẵn sàng đưa review hai phía** hoặc **cần sửa tiếp** (nêu gì). Rồi dừng — bước kế là review hai phía, không phải code.
