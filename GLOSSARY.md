# Reactive Storage

This context distinguishes values requested by mutations, representations held in storage, and values interpreted by readers.

## Language

**Mutation input**:
The logical value requested by a write, or produced by an update transformation, before conversion to a stored representation.
_Avoid_: Stored value, raw value

**Stored representation**:
The representation actually held under an existing key after the storage's retention and normalization rules apply. A stored null representation is distinct from an absent entry.
_Avoid_: Mutation input, logical value

**Logical value**:
The value obtained by interpreting a stored representation with a selected decoder, including any default chosen for a missing key. Different decoders can assign different logical values to the same storage state.
_Avoid_: Raw value, original value

**Read-time state**:
The storage state captured by a particular read. It need not be the state at the mutation that prompted the read or at the time the interpreted value reaches the reader.
_Avoid_: Mutation snapshot

**Key presence**:
Whether an entry exists for a key, independently of its stored representation or decoded logical value.
_Avoid_: Nullness

**Storage invalidation**:
A notification that a previously observed storage value may no longer be current. It does not establish that the logical value changed or describe a particular mutation snapshot.
_Avoid_: New value, value-changed event

**Invalidation scope**:
The keys whose observed state may need to be refreshed. The scope can name particular keys or cover all observed keys, including those currently absent from storage.
_Avoid_: Changed entries

**Raw refresh**:
The stage of a reload that refreshes the stored representations available to readers. It is separate from interpreting the reload result for its caller.
_Avoid_: Successful reload
