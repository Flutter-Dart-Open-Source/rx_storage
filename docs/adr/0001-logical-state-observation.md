---
status: accepted
accepted_on: 2026-11-22
---

# Use one logical-state contract for key observation

The existing key stream combines an initial decoded storage read with mutation-input notifications, which can disagree with subsequent reads when encoding changes a value or a decoder supplies a default. We decided to keep one `observe` method and interpret storage invalidations through each subscriber's read and decoder, aligning its value semantics with `observeAll`. The user accepted the complete design and narrow scope on 2026-11-22; this acceptance does not authorize implementation or release.

## Considered options

- Keep mutation-input notifications and document the codec round-trip conditions. This preserves behavior and avoids additional reads, but does not provide one logical-state interpretation across reads and notifications.
- Add an opt-in state-observation method. This preserves the current method but leaves callers choosing between two per-key stream contracts; the user prefers one method.
- Change the existing method to read and decode on invalidation. This provides one per-key contract while adding reads, decoder calls, and consumer migration work.

## Scope

- Keep the first change focused on logical-state observation, the invalidation and reload integration it requires, and the related documentation and validation.
- Keep one per-key `observe` method and accept a coordinated breaking change in `rx_storage` and `rx_shared_preferences`.
- Public logger-schema redesign and removal of key tracking are outside the initial scope. Distinguish any adaptation required for correctness from optional cleanup.
- Keep `Storage.write` returning `Future<void>`. Observation must not invoke the encoder or move encoded-null retention/deletion policy out of the adapter. No outcome interface, state-observation method, shared-read cache, or invalidation coalescing is required by this design.

## Decision

- Listening to `observe` performs an initial adapter read with that observer's decoder and options. Every relevant invalidation performs another read with the same decoder and options, including when a key has been removed and the decoder receives null.
- Key observation uses read-time state. It may skip intermediate mutation states or emit the same logical value for multiple invalidations; sequential read/decode conversions do not imply mutation snapshots. Do not add implicit distinct-value filtering.
- Process invalidations sequentially per subscriber without coalescing pending signals. Each independently listened stream performs its own reads and decoding; accept the additional read cost without introducing shared reads or a cache in the first change.
- Successful write/update/remove operations invalidate their key. A successful clear and a successful raw refresh invalidate all key observers, including those whose keys are missing or whose logical values are unchanged. `observeAll` continues rereading on every invalidation.
- A successful raw refresh triggers global invalidation without waiting for optional decoding of the reload result. That decoding can still fail the returned reload future without retracting the invalidation, while each observer uses its own decoder. The returned decoded reload map is not supplied as the input to observer decoders.
- Key presence remains distinct from logical value. A key read passes null for both an absent key and a stored-null entry, allowing a decoder default; bulk reads omit absent keys and retain existing entries whose decoding returns null.
- Preserve existing disposal behavior: close the change source and stop new publication, while already received invalidations and read/decode conversions may drain before the observer receives done. Completing the wrapper's dispose future does not guarantee every observer has reached done. Caller cancellation stops delivery to that subscription without cancelling already started read/decode work through the current interface. Do not add a discard-pending-results policy.

## Error boundaries

- Mutations invalidate only after the adapter reports success. A failed mutation still fails its future and does not add automatic invalidation, rollback, retry, or recovery reads, even if an adapter partially changed storage before reporting failure.
- An update's own read, decoder, transformer, and encoder remain part of that mutation and can fail its future. Reads and decoding performed only by observers instead report errors to their respective streams; successful mutations do not wait for observer conversions or become failures because an observer cannot decode.
- Raw refresh failure does not invalidate. Raw refresh success followed by reload-result decoding failure follows the explicitly agreed separation above.

These boundaries retain existing mutation error handling while deliberately separating raw-refresh invalidation from decoding of the returned reload map. They do not introduce error recovery.

## Implementation surface

- In `rx_storage`, use an internal key/global invalidation path shared by `observe` and `observeAll`, keep the observer's decoder/options at the read, and adapt mutation success handlers and disposal without adding another public observation method.
- In `rx_shared_preferences`, split raw refresh success from decoding the returned reload map so global invalidation can occur between those stages. Preserve adapter-owned null deletion and retain key tracking in the initial scope; do not use its removed-key list to limit global invalidation.
- Preserve the public logging schema. Diagnostic mutation/reload payloads may need to be handled separately from the internal invalidation scope; subscriber data/error logs describe what that observer actually receives.
- Update contract documentation, migration notes, changelogs and package tests in both repositories. Use a core major dependency constraint that actually includes the new behavior when integrating preferences; do not change the native `shared_preferences` dependency for this decision alone.

## Required validation before release

- Cover write/update, synchronous/asynchronous encoders, retained/deleted encoded null, null input encoded to non-null, decoder defaults, existing/new subscribers, presence and bulk-map topology, and observer errors independently from mutation outcomes.
- Use controlled async gates to cover read-time ordering, duplicate latest values, per-subscriber read counts, no coalescing, global clear/refresh including missing keys, and a raw refresh followed by a failing decoder of the returned reload map.
- Retain success/failure/disposal tests for mutations and add observer tests proving source-close draining, explicit subscription cancellation, and completion of already started read/decode work without uncaught asynchronous errors. Include a failed adapter write after partial mutation without promising rollback or automatic refresh.
- Record read/decoder call counts and exercise a slow-subscriber burst to make the accepted cost visible. Do not claim measured latency or bounded buffering without evidence, and do not introduce coalescing or shared-read optimization as part of this validation.
- Run the relevant repository analyzer, formatter and complete test gates. Preferences coverage must include legacy, async and cached adapters. Update the migration notes for the coordinated breaking releases; passing baseline tests is not evidence that this unimplemented design already passes.

## Verified constraints

- With one read per invalidation and per subscriber, K relevant signals and N subscribers add K x N adapter-read attempts. Legacy/cached preferences read a local cache; async preferences issue a key-scoped `getAll` call. This is a source-derived cost model, not a latency benchmark.
- The investigated logger shares the notification subject, but that implementation coupling does not make a public `KeysChangedEvent` schema redesign a prerequisite for logical-state observation. Diagnostic payloads and invalidation scopes can be handled separately.
- In the investigated preferences implementation, reload can refresh its cache and then fail while decoding its returned map, producing no notification. Keeping that boundary would prevent subscribers with valid independent decoders from reacting to a known successful refresh.
- Slow asynchronous decoding can leave invalidations buffered. This design does not guarantee bounded buffering, immutable mutation snapshots, or cancellation of an already running decoder.
- Sequential asynchronous observation orders the observer's read/decode conversions, not storage mutations. Two conversions can read the same newer state, and a value captured by a read may already be older when its asynchronous decoding finishes and emits.
- A gated public-interface repro on the investigated checkout confirmed that closing the change source can let `dispose()` complete while an observer decoder is pending. The observer can subsequently emit data or an error and then done; buffered `observeAll` invalidations can also start another read/decode after disposal. Closing the source alone therefore does not establish a discard-pending-results policy. The [recorded disposal repro results](../research/encoded-null-semantics.md#disposal-repro-2026-11-22) cover eight passing success/error/cancellation cases and support the retained disposal behavior; the temporary repro script is not versioned.

The source-backed investigation is in [encoded-null-semantics.md](../research/encoded-null-semantics.md), and the shared terms are in [GLOSSARY.md](../../GLOSSARY.md). Implementation, commits, pushes, publication and release remain outside the scope of this design approval.
