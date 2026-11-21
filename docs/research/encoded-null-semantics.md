# Write/update, encoded null và key-stream notifications

> Design accepted, 2026-11-22: anh đã chốt một `observe` theo logical state, chấp nhận breaking change và scope hẹp trong [ADR accepted](../adr/0001-logical-state-observation.md). Khuyến nghị opt-in bên dưới là kết quả khảo sát ban đầu, đã được thay bởi ADR này. Đây là phê duyệt thiết kế, chưa phải yêu cầu implement.

Khảo sát ngày 15/11/2026, chỉ đọc source và chạy kiểm chứng. Nội dung bên dưới giữ lại kết quả và đề xuất ở thời điểm khảo sát; quyết định thiết kế cuối cùng xem ADR phía trên. Production code, tests và dependency chưa thay đổi.

**Kết luận:** checkout hiện tại chủ đích dùng hai semantics khác nhau: `observe(key)` đọc và decode lúc subscribe, rồi phát input của mutation; `observeAll` đọc lại state và decode ở mỗi notification. Hai trường hợp được nêu đều tái hiện được, cả với adapter giữ encoded null. Quy tắc encoded null xóa key ở preferences adapter đang đúng contract. Nếu muốn key stream phản ánh logical state qua decoder, phần thay đổi phải nằm ở `rx_storage`, có tích hợp contract/tests ở `rx_shared_preferences`.

**Khuyến nghị ban đầu, đã được thay bởi ADR:** giữ nguyên `observe` hiện tại để tương thích. Nếu cần logical-state observation, chọn phương án B bên dưới: một cách observe có opt-in ở core, nhận invalidation rồi đọc bằng decoder của từng subscriber. Chấp nhận state tại thời điểm đọc, giống `observeAll`. Chưa cần đổi `Storage.write` hay thêm `WriteOutcome`. Nếu muốn đổi default của `observe`, cần coordinated breaking release. Phương án A là lựa chọn nhỏ nhất nếu anh quyết định input notifications đã đáp ứng nhu cầu.

## 1. Checkout, hướng dẫn và phạm vi bằng chứng

| Repo | Branch / commit | Phiên bản trong pubspec | Trạng thái đầu khảo sát |
| --- | --- | --- | --- |
| `rx_storage` | `master` / `2ac17f2c288c187e34dda75efe1a35907f092916` | `4.0.0`, HEAD cũng mang tag `4.0.0` | Clean |
| `rx_shared_preferences` | `master` / `2fc088225125ebe51d4049144a865787fdc8e961` | `5.0.0`; phụ thuộc `rx_storage ^4.0.0`, `shared_preferences ^2.5.4` | Clean |

Đã đọc `AGENTS.md` của cả hai repo và `rx_shared_preferences/docs/agents/domain.md`. `rx_storage` không có domain guide, glossary hoặc ADR trong checkout. Domain guide của preferences dẫn tới `GLOSSARY.md` và `docs/adr/`, nhưng hai nơi đó chưa tồn tại. Không có ADR hiện hữu cần đảo quyết định. Các version ở đây là metadata checkout, không phải khẳng định version mới nhất trên registry. Nguồn: [core pubspec][core-pubspec], [preferences pubspec][prefs-pubspec], [domain guide][prefs-domain].

**Đã thực thi:** bộ test CI entry point của core và repro Dart tạm qua `package:rx_storage/rx_storage.dart`, dùng SDK cài sẵn Dart `3.10.3`. Không chạy `pub get`, không sửa dependency, không chạy Flutter tests ở preferences. **Chỉ đối chiếu source:** ba adapter preferences, tracking, reload và expectations trong tests preferences. Repro adapter xóa null là mô hình in-memory của chính sách đó, không phải một lần chạy plugin native.

## 2. Bốn giá trị cần tách biệt

Gọi `x` là input của write, `e = encoder(x)` là encoded representation. Adapter áp dụng chính sách lưu/xóa để tạo state `S = (exists, raw)`. Logical value với decoder `D` là `D(raw)`; adapter đưa `null` vào decoder khi key thiếu.

| Khái niệm | Ví dụ | Ai quyết định |
| --- | --- | --- |
| Input `x` | `'hello'` hoặc `null`; với update là kết quả transformer | Caller / transformer |
| Encoded `e` | `null`, `'hello'`, JSON string… | Encoder |
| Key tồn tại / raw representation | `(true, null)` khác `(false, không có entry)` | Adapter / backing store |
| Logical value `D(raw)` | `null`, `'DEFAULT'`, domain object… | Decoder của lần read/subscriber |

`Decoder` không nhận bit `exists`, nên thiếu key và stored null không thể phân biệt qua callback này. `containsKey` phân biệt được, nhưng gọi riêng `containsKey` và `read` không tạo snapshot atomic. `EntryDecoder` chỉ chạy cho entry tồn tại và decoded null giữ entry trong map. Những điểm này đã được ghi rõ trong [storage.dart:3–57][storage-contract]. Stream giá trị hiện tại cũng không mang key existence.

## 3. Trace source hiện tại

| Bước | Hành vi đã kiểm chứng từ source | Nguồn |
| --- | --- | --- |
| `write` | Enqueue theo key rồi gọi `_writeWithoutSynchronization` | [real_storage.dart:346–354][core-write-entry] |
| `update` | Cùng queue theo key: read với decoder của update → transformer sync/async → cùng `_writeWithoutSynchronization` | [real_storage.dart:360–385][core-update] |
| Core gọi adapter | Chuyển nguyên input, encoder, options vào `Storage.write`; không tự encode | [real_storage.dart:141–148][core-write] |
| Encoding / persistence | InMemory gọi encoder, chờ kết quả rồi `_map[key] = encoded`, kể cả null | [in_memory_storage.dart:52–57][memory-write] |
| Preferences persistence | Cả legacy/async/cached gọi encoder một lần, chờ nếu async. Encoded null đi vào `remove(key)`; non-null đi vào setter tương ứng | [legacy:65–95][prefs-legacy-write], [async:46–65][prefs-async-write], [cached:58–88][prefs-cached-write] |
| Adapter completion | Contract chỉ trả `Future<void>`, không báo raw state hay deletion. Hoàn tất không đồng nghĩa disk durability | [storage.dart:21–27,71–78][storage-write-contract] |
| Notification | Sau adapter success, tạo `KeyAndValue(key, input, T)`, `sendChange`, rồi log `WriteSuccessEvent`. Không đọc lại, không decode | [real_storage.dart:147–164][core-write] |
| `observe(key)` | Dummy initial event gọi adapter `read(key, decoder, options)`. Event sau đó lấy `entry.value` và cast sang type observer; không gọi decoder | [real_storage.dart:394–418][core-observe] |
| `observeAll` | Initial event và mọi change map đều trigger `readAll(decoder, options)` qua `asyncMap` | [real_storage.dart:423–431][core-observe-all] |

`useStorageWithHandlers` chờ operation thành công rồi mới chạy success callback. Encoder/backend thất bại đi qua failure handler và rethrow, không đi vào `sendChange` của write. Việc adapter có thể đã thay đổi data trước khi báo lỗi vẫn phụ thuộc adapter; core không rollback. Nguồn: [real_storage.dart:174–199][core-handlers], [transactional_storage.dart:25–34][update-contract].

Các đường đối chiếu:

- `remove`: cùng queue theo key, đợi adapter remove rồi phát literal null, bỏ qua decoder. [real_storage.dart:324–343][core-remove].
- `clear`: dùng queue theo wrapper instance, đọc raw `readAll` để lấy danh sách key trước khi clear, sau success phát null cho danh sách đó. Không chung queue với per-key writes. [real_storage.dart:297–319][core-clear].
- Initial read và fresh subscriber đều thực sự đọc adapter. `observeAll` cũng đọc state, nhưng mỗi emission là state lúc read chạy, không phải snapshot của mutation đã trigger nó. [observe contract:34–68][observe-contract].
- Direct adapter changes và wrapper khác không tự tạo notification cho wrapper này. Reads không vào write queue. [rx_storage.dart:8–12][rx-contract], [transactional_storage.dart:30–34][update-contract].

Ở preferences, `RealRxSharedPreferences` truyền `KeyTrackingSharedPreferences` vào core và kế thừa write/update/observe. Tracking capture encoded result trong wrapper encoder, cập nhật known keys **sau** delegate write success và không gọi user encoder lần thứ hai. Kết quả cuối cùng vẫn là void, nên thông tin deletion không được truyền về core. [wrapper:10–23][prefs-wrapper], [tracking:64–94][prefs-tracking-write].

## 4. Kết quả repro qua public interface

Repro seed key bằng `'seed'`, chờ initial emissions rồi mới mutation. Đồng thời mở observer identity `I(raw) = raw as String?`, observer default `D(raw) = raw as String? ?? 'DEFAULT'`, và hai `observeAll` tương ứng. Các ô dưới là **kết quả thực thi**, không chỉ suy luận.

| Adapter | Input → encoded | Key còn? | Existing key stream, cả I và D | Read / fresh I | Read / fresh D | `observeAll(I)` sau ghi | `observeAll(D)` sau ghi |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Built-in InMemory | `'hello'` → null | Có | `'hello'` | null | `'DEFAULT'` | `{key: null}` | `{key: 'DEFAULT'}` |
| Xóa encoded null, mô hình | `'hello'` → null | Không | `'hello'` | null | `'DEFAULT'` | `{}` | `{}` |
| Built-in InMemory | null → `'hello'` | Có | null | `'hello'` | `'hello'` | `{key: 'hello'}` | `{key: 'hello'}` |
| Xóa encoded null, mô hình | null → `'hello'` | Có | null | `'hello'` | `'hello'` | `{key: 'hello'}` | `{key: 'hello'}` |

Mỗi dòng chạy với `write` và `update`, encoder sync và async: **16 mutation scenarios**, mỗi scenario gọi user encoder đúng một lần. `WriteSuccessEvent` và `KeysChangedEvent` cũng mang input trong các lần chạy này. Với update, repro kiểm tra transformer nhận decoded seed; event sau ghi là kết quả transformer, không phải kết quả decode state mới.

Các kiểm chứng khác:

| Scenario | Kết quả thực thi |
| --- | --- |
| Remove hoặc clear key đang có, observer D | Existing stream: `['seed', null]`; fresh stream: `'DEFAULT'`; bulk: `{}`. Chạy 2 scenarios |
| Encoder throw sync / future error, backend lỗi trước mutation | Write/update fail, key stream và bulk không có event mới; seed còn nguyên |
| Backend mutate rồi báo lỗi | Write/update fail và không notify, dù raw đã thành null hoặc key đã mất. Đây là adapter fault injection, không khẳng định bundled preferences adapters luôn gặp tình huống đó |
| Clear đang chờ backend, write tạo key sau bước clear scan | Existing key stream: `[null, 'hello']`, read cuối: null, key không tồn tại; bulk: `[{}, {key: 'hello'}, {}]` |

Có **16 failure scenarios**: hai operations × hai null policies × bốn failure points. Clear interleaving dùng Completer gate, không dựa vào sleep. Nó xác nhận queue theo wrapper của clear và queue theo key có thể interleave, và danh sách key trước clear có thể thiếu key vừa được tạo. Chuyển notification payload sang raw state đơn thuần không tự sửa được phạm vi invalidation này.

Artifacts tạm ngoài worktree, không được đưa vào repository:

- Repro source: `rx-storage-null-repro-20261115.dart`.
- Kết quả: `rx-storage-null-repro-20261115.jsonl` gồm 35 records; stdout trong `rx-storage-null-repro-20261115.log`.
- Existing-suite log: `rx-storage-existing-suite-20261115.log`, **101 tests passed**, exit 0. Entry point có perf phase trước khi đăng ký tests.

Các artifacts trên được tạo trong `/private/tmp` trên máy khảo sát. Bảng kết quả ghi lại observations của lần chạy đó; các file tạm không phải tài liệu có thể tải từ repository.

Lệnh đã chạy trên máy khảo sát từ root repo, dùng package resolution sẵn có:

```sh
/Users/hoc.nguyen/Desktop/Flutter_SDK/flutter/bin/cache/dart-sdk/bin/dart \
  --packages=.dart_tool/package_config.json \
  /Users/hoc.nguyen/.pub-cache/hosted/pub.dev/test-1.31.1/bin/test.dart \
  test/rx_storage_test.dart --chain-stack-traces --reporter=expanded

/Users/hoc.nguyen/Desktop/Flutter_SDK/flutter/bin/cache/dart-sdk/bin/dart \
  --enable-asserts --packages=.dart_tool/package_config.json \
  /private/tmp/rx-storage-null-repro-20261115.dart
```

Dùng SDK binary trực tiếp vì shell `dart` đi qua Flutter wrapper và thử ghi `engine.stamp` ngoài sandbox. Không đổi SDK/cache để chạy khảo sát. Chưa chạy SDK matrix hoặc kiểm chứng native disk persistence.

### Disposal repro (2026-11-22)

Repro bổ sung dùng public interface trên cùng core commit và Dart `3.10.3`, với Completer giữ initial decoder. Chạy **8 cases pass**, không có uncaught error và không case nào chạm safety timeout:

| Scenario | Trước khi release decoder | Sau khi release decoder |
| --- | --- | --- |
| `observe`, success/error | `dispose()` đã complete; observer chưa nhận done | Emit value/error rồi done |
| `observeAll`, success/error, có write invalidation đang chờ | `dispose()` đã complete; observer chưa nhận done | Emit initial value/error, thực hiện read/decode tiếp cho invalidation đang chờ, rồi done |
| Bốn cases tương ứng có cancel subscription trước release | Cancel hoàn tất | Không giao thêm data/error/done cho subscriber và không chạy conversion tiếp theo |

Kết quả xác nhận close change source không tự hủy read/decoder đang chạy hoặc bỏ các signals đã buffer trong observer. Đây là behavior hiện tại được giữ trong ADR, không phải một guarantee mới rằng disposal hủy công việc bên dưới.

Repro `rx-storage-dispose-stream-repro-20261122.dart`, JSONL traces và stdout được giữ tạm ngoài worktree trong `/private/tmp`, không được đưa vào repository.

## 5. Contract: bug hay giới hạn có chủ đích?

**Theo contract hiện tại, đây là hành vi được mô tả và được tests giữ lại.** Public Dartdoc core nói original write value được phát mà không đọc/decode lại, remove/clear bypass decoder. README có bảng cùng nghĩa. Preferences còn ghi rõ encoded null xóa key nhưng notification vẫn mang input. [core interface:42–46][observe-contract], [core README:85–124][core-readme-observe], [preferences interface:25–27][prefs-input-contract].

Vì vậy không nên phát hành một thay đổi silent dưới nhãn “sửa null adapter”. Có một giới hạn thiết kế rõ ràng: `observe(key)` là initial state read cộng mutation input notifications, không phải một projection đồng nhất của stored logical state. Nó cũng không phải pure mutation log vì event đầu không phải mutation.

Hai encoder trong đề bài kết hợp identity decoder không bảo toàn round-trip. Nhưng encoder đó **không tự thân bất hợp lệ**: write không nhận decoder và API không cấm codec lossy hoặc normalization. Với `encoder(null) = 'hello'`, một decoder coi `'hello'` là sentinel null có thể trả lại null đúng ý đồ. Với `encoder('hello') = null`, decoder(null) có thể trả `'hello'`. Chỉ so input với một read dùng decoder identity khác codec không đủ để kết luận bug. Repro ở trên còn dùng cùng decoder cho old/new subscribers và cho thấy sự lệch là có thật khi decoder đó không khôi phục input.

Nếu muốn existing/new subscribers khớp sau **writes** trong contract hiện tại, cần điều kiện cho từng key và từng observer liên quan:

```text
D(raw thực sự đọc được sau adapter.write(x, E)) ≡ x
```

Phải tính cả adapter normalization/deletion, không chỉ công thức `D(E(x))`. Các decoder cùng observe một key phải tương thích với logical type và mọi encoder ghi key đó. Ngay cả invariant này vẫn chưa làm remove/clear nhất quán với default decoder: mutation phát null trong khi `D(null)` có thể khác null. Muốn đồng nhất cả deletion theo contract hiện tại thì còn cần `D(null) == null`, hoặc consumer chấp nhận null tombstone là một tín hiệu riêng.

Initial read và `observeAll` nhất quán ở việc dùng decoder lên raw state. Bulk vẫn khác key stream về topology theo chủ đích: missing key bị bỏ khỏi map, không sinh `{key: D(null)}`; stored null có entry để decode. Cùng một thời điểm quiescent, `read`/fresh key observer có thể trả default trong khi bulk không chứa key. Đây không phải mâu thuẫn.

### Tests/docs hiện hữu đã quyết định gì

| Nguồn | Điều đã pin |
| --- | --- |
| [in_memory_rx_storage_test.dart:32–64][test-key-contract] | Mutation phát original value; decoder default chỉ ở initial read, remove vẫn null |
| [in_memory_storage_test.dart:23–38,55–74][test-memory-null] | Stored null giữ key; missing có thể decode default; null input vẫn được encode |
| [in_memory_rx_storage_test.dart:66–155][test-bulk-contract] | Bulk đọc encoded/decoded entries, giữ stored null, bỏ removed/cleared keys |
| [in_memory_rx_storage_test.dart:186–277][test-stream-errors] | Bulk decode error/recovery, key type errors, failed writes/update và serialized async increments |
| [decoded_storage_test.dart:40–83][test-bulk-null] | Decoded null/default giữ key; async decode dùng entry snapshot |
| [preferences bulk_decoding_test.dart:523–565][prefs-test-input] | Encoded null từ input null/non-null xóa key nhưng stream phát input; null input encoded non-null vẫn phát null; encoder một lần |
| [preferences bulk_decoding_test.dart:216–240][prefs-test-read-time] | Bulk có thể emit `[1,3,3]` khi initial decoder bị giữ, không replay `[1,2,3]` |
| [lifecycle_test.dart:90–116,177–245][test-lifecycle] | Started writes/update có thể xong sau dispose; queued writes fail; không thêm notification/log sau dispose trong các cases này |

Các expectations preferences ở bảng là **đã đọc source, chưa chạy lại**. Test double cũ trong core còn thực hiện `remove` bằng `_setValue(key, null)`, giữ entry trong map. Vì vậy không dùng riêng các tests dựa fake đó để kết luận backing key đã mất; repro ở đây dùng InMemory remove thực sự và adapter mô hình xóa key. [fake_storage.dart:67–75,118][test-fake-remove]. Những quyết định còn thiếu là có muốn một API state observation riêng hay không, state-at-read hay mutation snapshot, và chính sách default/removal/error cho API đó. Hành vi legacy đã khá rõ, không phải khoảng trống cần đoán.

Preferences reload là đường thứ ba: publish snapshot raw hoặc entry-decoded trực tiếp, cộng null cho removed keys; không dùng decoder riêng của từng key observer. Reload/clear chung queue, per-key writes có thể xen vào, snapshot cũ có thể notify sau write mới. [real_rx_shared_preferences.dart:25–45][prefs-reload], [interface:119–141][prefs-reload-contract]. Chỉ sửa write không tạo được state semantics nhất quán với đường này.

## 6. Ba phương án khả thi

| Phương án | Semantics đạt được | Interface, encoder và I/O | Trade-off / điều kiện chọn |
| --- | --- | --- | --- |
| **A. Giữ input contract; làm rõ codec invariant** | Giữ mọi behavior hiện tại. Agreement với read chỉ khi codec/decoder thỏa invariant; deletion default vẫn là tombstone | Không đổi API. User encoder vẫn một lần. Không thêm reads | Nhỏ nhất, phù hợp khi caller muốn input events và codecs được kiểm soát. Không đáp ứng logical-state observation với arbitrary decoder/default/normalization |
| **B. Invalidation rồi read/decode theo observer** | Mỗi event lấy logical state khi read chạy. Encoded null giữ/xóa đều xử lý qua adapter read. Default áp dụng nhất quán trên key read | Giữ `Storage.write: Future<void>`. Encoder vẫn một lần. Thêm một adapter read + decoder mỗi observer cho mỗi relevant signal | Nhỏ nhất cho mục tiêu logical-state. Có I/O/latency và decoder side effects; có thể thấy state mới hơn, lặp latest state. Chọn nếu chấp nhận semantics giống `observeAll` |
| **C. Adapter báo outcome có state snapshot** | Nếu mang raw snapshot, từng subscriber decode state của mutation; nếu chỉ báo removed thì chỉ có tombstone policy | Đổi return type là breaking, hoặc thêm capability có fallback rõ. Encoder một lần. Có thể không cần read thêm nếu adapter biết canonical raw state | Cần nếu phải giữ từng mutation state hoặc I/O của B quá đắt. Phức tạp hơn về adapter/decorator/clear/reload/copying. Không chọn chỉ vì thấy encoded null |

### A. Ràng buộc rõ, không đoán null trong core

Document invariant theo key và phân biệt input events với reads. Không thêm runtime rejection chung cho codec: write không có decoder để kiểm chứng, mỗi subscriber lại có thể dùng decoder khác. Tự gọi encoder lần nữa để kiểm tra có thể tạo side effects, random result, thêm latency hoặc lỗi khác lần write.

`rx_shared_preferences` tiếp tục xóa key khi encoded null theo [SharedPreferencesLike:4–15][prefs-like]. Core tiếp tục cho phép `InMemoryStorage` giữ null. Nếu consumer cần logical state ngay bằng API có sẵn, có thể derive từ `observeAll((_, raw) => raw)` rồi áp decoder cho `map[key]`, kể cả key thiếu. Cách này đọc toàn bộ storage và nhận signal từ mọi key, nên là workaround có chi phí, không phải state stream theo key đã được tối ưu.

### B. State-at-read trong core, opt-in trước

Luồng đề xuất là successful mutation → signal → adapter.read bằng decoder/options của subscriber → data/error. Decoder của update chỉ dùng cho read-modify-write; nó không đại diện cho decoder của mọi subscriber. Không cast encoded representation thành logical `T`.

Các điều kiện thiết kế cần giữ:

- Mutation future vẫn phản ánh các bước của mutation: encode/write với write, thêm read/transform với update. Một observer decode fail tạo stream error của observer đó, không biến một write đã persist thành failed write. Subscriber khác vẫn có thể decode thành công.
- Read/async decoder theo thứ tự của từng stream. Chờ initial event vẫn phải nhận/buffer các signal đến trong lúc initial read/decoder chưa xong. Không hứa mỗi write tương ứng một state snapshot khác nhau; rapid writes có thể cho `[latest, latest]` như bulk hiện tại.
- Không giữ write queue chờ mọi subscriber decode. Decoder có thể chờ một write khác trên cùng key, gây deadlock nếu buộc chúng vào queue. Không gọi public `write`/`update` từ trong chính queue để normalize lại.
- Clear cần global invalidation cho state observers nếu muốn bao phủ clear/write interleaving đã repro. Chỉ tái dùng map key trước clear sẽ giữ lỗ hổng đó. Invalidation của reload phải đi vào cùng đường state read, bỏ qua payload đã decode của reload đối với **state observer**, còn return value của reload có thể giữ nguyên.
- Public/protected `sendChange` đang được preferences dùng. Phải giữ đường tích hợp này hoặc migration rõ. Một internal signal phân biệt phạm vi key/global có thể cần cho clear, nhưng không cần outcome API của adapter để giải quyết encoded null.
- Không tự `containsKey` trước mỗi read: logical decoder không cần presence bit, thêm call còn không atomic. API vẫn không expose sự khác nhau giữa missing và stored null bằng value đơn lẻ.

Chi phí: với `N` key observers, mỗi notification relevant có thể tạo `N` reads/decoder calls ngoài I/O hiện có. InMemory/cached/legacy thường đọc local memory; async preferences `read` dùng `getAll(allowList: {key})`, nên có thêm platform/backend read. Cached read vẫn là state của cache hiện tại; external changes vẫn cần reload. [async adapter:33–43][prefs-async-read], [cached:45–55][prefs-cached-read]. Chưa có benchmark chi phí này, không nên đưa con số latency.

Về API, thêm instance method vào `abstract interface RxStorage` sẽ buộc custom implementors đổi, dù giữ `observe` cũ. Một factory/mode opt-in không thêm yêu cầu implementation có thể tránh source break đó, nhưng đổi behavior của `observe` trên cùng type vẫn đụng lời hứa input notifications hiện tại. Generic consumers nhận `RxStorage` có thể bị ảnh hưởng dù người tạo wrapper đã opt-in. Em ưu tiên API/capability/facade state riêng, giữ `observe` cũ. Nếu chọn mode thì phải định nghĩa contract theo mode trong Dartdoc và audit generic consumers, không suy ra minor-safe chỉ từ việc thêm factory. Một extension chỉ dựa API hiện có có thể dùng bulk workaround trên, đổi lại full-store reads. Cần chốt hình thức API sau khi chốt semantics, không mặc định một hook mới là bắt buộc.

### C. Outcome chỉ có ích khi nó báo đúng loại thông tin

Một boolean `removed` hoặc kết quả kiểu `written(input)` / `removed` đủ cho policy “delete emit null, writes khác emit input”. Nó **không** giải quyết null input → encoded non-null với identity decoder, decoder default sau deletion, hoặc các decoder khác nhau. Đó là contract input cộng tombstone, không phải logical state.

Nếu cần full state theo mutation, outcome phải mô tả ít nhất `present(raw)` và `absent`, phân biệt `present(null)` với absence. Raw phải là representation adapter thực sự đã chấp nhận, tính cả normalization. Mỗi subscriber vẫn phải gọi decoder của mình. Một logical value duy nhất từ adapter không thay thế được mọi decoder.

Cần capture outcome trong cùng per-key queue, trước khi operation kế tiếp được chạy. Không encode lần hai. Adapter nào không có snapshot đáng tin phải có fallback rõ, không silently dùng input rồi gọi đó là state. Nếu raw chứa mutable object, cần quyết định snapshot/copying: InMemory hiện giữ reference và chỉ shallow-copy bulk entries. [in_memory_storage.dart:9–15,32–37][memory-snapshot]. Outcome không tự bảo đảm immutable snapshot.

Đổi `Storage.write` từ `Future<void>` sang return outcome buộc adapter implementors/decorators cập nhật. Một optional capability giảm phạm vi breaking, nhưng thêm nhánh capability/fallback và phải được forwarding qua `KeyTrackingSharedPreferences`; leaf adapter có outcome mà decorator không chuyển tiếp thì core vẫn không thấy. Clear/reload/remove cũng phải có semantics tương ứng nếu API hứa snapshot cho mọi mutation. Snapshot từ writes không tự giải quyết ordering giữa clear/reload và queue theo key.

### Logging và disposal áp dụng cho B/C

Trong đường write/update hiện tại, `WriteSuccessEvent`, `WriteFailureEvent`, `KeysChangedEvent` mang input; `OnDataStreamEvent` là value key stream phát. `KeysChangedEvent` của remove/clear mang null, của preferences reload mang raw/entry-decoded values. KeysChanged được tạo từ cùng subject, còn các log checks và `sendChange` kiểm tra disposal. `observeAll` hiện không có `doOn` stream-data/error logging tương ứng. [write/log path:141–164][core-write], [logger setup:75–84][core-logger], [sendChange:202–215][core-send], [observe logging:409–431][core-observe], [reload:33–40][prefs-reload].

Nên giữ write-success log là requested input + adapter success, tránh âm thầm đổi ý nghĩa field sang raw hoặc logical value. Với B, stream-data log phản ánh decoded state của observer, và stream-error log phản ánh read/decode failure; không báo write failure cho lỗi đó. Với C, nếu cần log outcome thì tách rõ input, raw/presence và logical value, không dùng chung một payload không rõ nghĩa.

Queue vẫn chỉ serialize write/remove/update cùng key, không thành global transaction. [queue setup:125–138][core-queue], [AsyncQueue:67–80][async-queue]. Pending tasks bị reject khi dispose; active operation có thể xong nhưng phải giữ guard để không publish/log sau disposal. Async observer reads/decoders mới cần lifecycle cases riêng cho pending completion, cancellation và stream closure. Không để dispose mới vô tình đợi vô hạn một user decoder. [core dispose:434–442][core-dispose], [AsyncQueue:83–96][async-dispose].

## 7. Trách nhiệm và change surface dự kiến

**Nơi sở hữu fix cho logical-state observation là `rx_storage`; nơi sở hữu encoded-null deletion là preferences adapter.** Không có bằng chứng adapter đang áp sai chính sách persistence. Sửa preferences riêng bằng override write/update hoặc phát event “đính chính” sau write sẽ né core contract: các entry points là `@nonVirtual`, input event đã phát, correction dễ duplicate/reorder sau khi queue nhả, và update vẫn đi đường private dùng chung. [write:346–354][core-write-entry], [update:360–385][core-update].

| Package / khu vực | Nếu chọn B opt-in như khuyến nghị | Nếu chỉ chọn A | Nếu chọn C |
| --- | --- | --- | --- |
| Core implementation | Cách observe state, invalidation key/global, decoder/errors/log/disposal; giữ đường write/update hiện tại | Không production changes | Nhận outcome trong đường ghi chung; chuyển raw/presence tới state observers; xử lý remove/clear tương ứng |
| Core public API / exports | Factory/mode/helper được chốt; tránh thêm abstract instance requirement nếu muốn minor | Dartdoc/README codec invariant và ví dụ | Return type mới hoặc capability + fallback và exports |
| Core tests | `in_memory_rx_storage_test.dart`, stream/lifecycle suites; suite mới phải đăng ký ở aggregator | Thêm regressions hai cross-null codecs nếu muốn pin rõ hơn | Adapter outcome, decorators, snapshot/copying/ordering tests |
| Preferences adapters | Giữ nguyên encoded null → remove; thêm tests cho state observer ở legacy/async/cached | Không đổi persistence | Leaf adapters báo canonical outcome; tracking decorator forward outcome |
| Preferences reactive wrapper | Forward opt-in; reload signal đi qua core state observation. Keep existing key API default nếu chọn compatibility | Không đổi | Phối hợp write/update/reload event representation |
| Preferences tracking | Giữ capture encoded null một lần và success-only known-key changes; kiểm thử với reads từ state observers | Không đổi | Tránh capture/call encoder trùng, giữ tracking và outcome forwarding cùng success boundary |
| Docs/dependencies | Core README/Dartdoc/CHANGELOG; preferences README/MIGRATION/Dartdoc/CHANGELOG + constraint core khi thật sự dùng API mới | Docs/test-only, không cần bump dependency | Coordinated major hoặc minor capability tùy compatibility thực tế |

Với B, không có lý do từ khảo sát này để bump dependency `shared_preferences`. Existing getters/setters và typed updates identity-codec có thể giữ nguyên; custom-codec users chọn state mode khi cần. Nếu state mode là per-wrapper factory thay vì một phương thức observe riêng, toàn bộ consumers dùng wrapper đó phải biết stream-data behavior của mode.

## 8. Regression matrix trước khi implement

Chạy base cross-product `write/update × encoder sync/async × retain-null/delete-null × input→encoded cases`. Cases tối thiểu: non-null→null, null→non-null, null→null, non-null→non-null với round-trip và normalization. Cho mỗi case kiểm tra existing subscriber, fresh subscriber, read, containsKey và bulk bằng decoder identity, default và decoder đúng codec. Không chỉ so input với identity read rồi gọi là bug.

| Nhóm | Coverage cần có | Legacy A | State mode B / raw-snapshot C |
| --- | --- | --- | --- |
| Non-null → encoded null | Cả retain/delete; existing/fresh; write/update; sync/async | Existing phát input | Existing dùng `D(null)`; topology bulk vẫn khác retain/delete |
| Null → encoded non-null | Identity decoder và sentinel decoder matching codec | Existing phát null; fresh tùy decoder | Mọi key read dùng decoder tương ứng, không ép encoded thành T |
| Null → null, decoder default | Stored null và absence | Existing null, fresh default | Existing/fresh default tại state tương ứng; absence vẫn không xuất hiện trong bulk |
| Logical null khác raw null | JSON/sentinel non-null decode null | Value null không chứng minh deletion | Map giữ key khi decode null, containsKey true |
| Multiple observers | Cùng key, hai decoders/defaults/types/options | Type cast errors theo contract khi mutation type không khớp | Mỗi observer decode riêng; một decoder fail không ảnh hưởng mutation/subscriber khác |
| Update pipeline | Decoder/transformer sync/async; transformed input cross-null | Notify transformed input | Decode stored state cho observers; update decoder chỉ phục vụ read-modify-write |
| Encode failures | Sync throw/async error trước persistence | Fail, không signal; next queue task vẫn chạy | Tương tự; zero extra encode; không đọc state như thể success |
| Adapter failures | Trước mutation; sau partial mutation; encoded-null remove fail | Không signal; không giả định rollback | Chốt có giữ success-only invalidation không; không báo success giả |
| Read/decode failures | Initial và sau successful write; recover ở notification sau | Mutation không decode lại | Stream error, write vẫn success; không rollback write |
| Remove/clear | Existing/missing/stored null; default decoder; repeated operations | Tombstone null / danh sách key trước clear | `D(null)`; clear global invalidation nếu chọn promise này |
| Queue/races | Two writes; write/update/remove same key; delayed encoder; initial decoder blocked | FIFO inputs cùng key | B có thể lặp latest; C bảo toàn snapshots theo promise; clear/reload không được quảng cáo isolation toàn cục |
| Clear interleaving | Key sinh sau clear pre-scan, backend clear gated | Repro hiện giữ stale key-stream value | State mode phải được invalidate cả observer đó hoặc ghi rõ giới hạn |
| Preferences reload/tracking | External add/remove; encoded-null deletion rồi reload hai lần; null input stored non-null | Expectations hiện có | Own decoder của state observer; không double decode payload reload; knownKeys chính xác, không duplicate correction |
| Logging / lifecycle | Input vs raw/logical; queued/active disposal; pending initial/read/decode/cancel | Giữ tests hiện tại | Không event/log sau guard disposal; mutation status không phụ thuộc observer decoder; disposal không kẹt callback |
| Duplicate values | Repeated writes / no-op removals / same latest state | Không tự distinct | Giữ explicit duplicate policy, `.distinct()` là lựa chọn consumer nếu không đổi contract |

Với preferences chạy matrix trên legacy/async/cached và custom adapter phù hợp. Existing tests chứng minh policy hiện tại nhưng chưa phải regression suite cho B/C. Dùng Completer gates để kiểm ordering và failures, không thêm sleep-based timing tests.

## 9. Consumers, versioning và tích hợp

- A không đổi runtime. Có thể bổ sung docs/tests mà không đổi constraints.
- B với API state riêng có thể là minor nếu không thay contract của `observe` và không thêm abstract requirement làm custom implementors hỏng. Factory đổi semantics của `observe` cần review thêm method contract và generic consumers. Việc thêm method bắt buộc vào interface hoặc đổi default observe là breaking, kể cả call sites vẫn compile.
- C đổi return contract của `Storage.write` là breaking cho implementors/decorators. Optional capability giữ được legacy APIs chỉ khi fallback và behavior cũ được giữ rõ.
- Nếu thay `observe` default, consumers có thể thấy default thay null sau remove, decoder chạy nhiều lần hơn, TypeErrors/read errors khác, giá trị normalized thay input, độ trễ/I/O mới, và rapid writes không còn replay từng input. Widget state, stream assertions và logging consumers cần migration.
- `rx_shared_preferences ^4.0.0` ở đây là constraint cho core. Nó không tự nhận core `5.x`. Nếu chọn core major phải cập nhật constraint một cách chủ đích và đánh giá major của preferences vì public stream behavior và core types được expose. Nếu opt-in dùng API mới ở core `4.x`, nâng minimum constraint lên đúng bản chứa API, không giữ lower bound cũ rồi gọi API chưa tồn tại.

Khuyến nghị release/migration trên dựa vào contract đã ghi trong hai repo và quy tắc [semantic versioning của pub](https://dart.dev/tools/pub/versioning#semantic-versions). Không chọn số version phát hành cuối cùng ở bước khảo sát này.

## 10. Những quyết định anh cần chốt

Các câu hỏi dưới đây thuộc thời điểm khảo sát ban đầu. Câu trả lời cuối cùng đã được chốt trong ADR accepted phía trên.

1. **Ý nghĩa mong muốn:** giữ input notifications, hay có thêm logical-state observation? Em đề xuất giữ existing API và thêm opt-in state semantics ở core nếu đó là nhu cầu thực tế.
2. **Thời điểm state:** chấp nhận state lúc read chạy như `observeAll`, hay phải quan sát snapshot của từng mutation? Em chọn state-at-read để giữ thay đổi nhỏ. Nếu cần mọi mutation snapshot thì xem C.
3. **Default và deletion:** state observer có luôn gọi own decoder khi remove/clear/reload báo key thiếu không? Em đề xuất có, nghĩa là `D(null)` có thể non-null. Key existence tiếp tục là vấn đề riêng.
4. **Clear/reload và compatibility:** state mode có clear global invalidation và reload re-read bằng own decoder không? Em đề xuất có, giữ return payload `reload(decoder)` hiện tại nhưng không dùng payload đó làm logical value chung cho state observers.
5. **Failure boundary:** giữ nguyên success-only notification dù adapter mutate rồi fail, hay muốn thêm refresh-on-failure? Em đề xuất giữ success-only trong scope này, ghi rõ không rollback; refresh-on-failure là quyết định riêng có thêm I/O và error semantics.
6. **Bề mặt API và cost:** opt-in theo từng observe hay wrapper factory/mode, và thêm reads/decoder calls có chấp nhận được cho async preferences không? Chưa có số liệu để biện minh outcome API chỉ nhằm tối ưu I/O. Write-success logs nên tiếp tục báo input, stream-data logs báo logical data của mode được chọn.

Không có production/test/dependency implementation, commit, push hoặc publish trong khảo sát này.

[core-pubspec]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/pubspec.yaml#L3
[prefs-pubspec]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/pubspec.yaml#L3
[prefs-domain]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/docs/agents/domain.md#L1
[storage-contract]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/interface/storage.dart#L3
[storage-write-contract]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/interface/storage.dart#L71
[core-write-entry]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L346
[core-update]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L360
[core-write]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L141
[memory-write]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/storage/in_memory_storage.dart#L52
[core-observe]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L394
[core-observe-all]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L423
[core-handlers]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L174
[update-contract]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/interface/transactional_storage.dart#L25
[core-remove]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L324
[core-clear]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L297
[observe-contract]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/interface/rx_storage.dart#L34
[rx-contract]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/interface/rx_storage.dart#L8
[prefs-wrapper]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/lib/src/impl/real_rx_shared_preferences.dart#L10
[prefs-tracking-write]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/lib/src/impl/key_tracking_shared_preferences.dart#L64
[prefs-legacy-write]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/lib/src/impl/legacy/shared_preferences_adapter.dart#L65
[prefs-async-write]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/lib/src/impl/async/shared_preferences_async_adapter.dart#L46
[prefs-cached-write]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/lib/src/impl/async/shared_preferences_with_cache_adapter.dart#L58
[core-readme-observe]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/README.md#L85
[prefs-input-contract]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/lib/src/interface/rx_shared_preferences.dart#L25
[test-key-contract]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/test/storage/in_memory_rx_storage_test.dart#L32
[test-memory-null]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/test/storage/in_memory_storage_test.dart#L23
[test-bulk-contract]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/test/storage/in_memory_rx_storage_test.dart#L66
[test-stream-errors]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/test/storage/in_memory_rx_storage_test.dart#L186
[test-bulk-null]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/test/storage/decoded_storage_test.dart#L40
[prefs-test-input]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/test/bulk_decoding_test.dart#L523
[prefs-test-read-time]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/test/bulk_decoding_test.dart#L216
[test-lifecycle]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/test/storage/lifecycle_test.dart#L90
[test-fake-remove]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/test/fake_storage.dart#L118
[prefs-reload]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/lib/src/impl/real_rx_shared_preferences.dart#L25
[prefs-reload-contract]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/lib/src/interface/rx_shared_preferences.dart#L119
[prefs-like]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/lib/src/interface/shared_preferences_like.dart#L4
[prefs-async-read]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/lib/src/impl/async/shared_preferences_async_adapter.dart#L33
[prefs-cached-read]: https://github.com/hoc081098/rx_shared_preferences/blob/2fc088225125ebe51d4049144a865787fdc8e961/lib/src/impl/async/shared_preferences_with_cache_adapter.dart#L45
[memory-snapshot]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/storage/in_memory_storage.dart#L9
[core-logger]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L75
[core-send]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L202
[core-queue]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L125
[async-queue]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/async/async_queue.dart#L67
[core-dispose]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/impl/real_storage.dart#L434
[async-dispose]: https://github.com/Flutter-Dart-Open-Source/rx_storage/blob/2ac17f2c288c187e34dda75efe1a35907f092916/lib/src/async/async_queue.dart#L83
