## 1.1.0 - May 9, 2021

-   Update `rxdart` to `0.27.0`.

## 1.0.0 - Apr 30, 2021

-   Stable release for null safety.
-   Add `RxStorage.executeUpdate`: Read–modify–write style.
-   Synchronize writing task by key.
-   Internal refactoring, optimize performance.

## 1.0.0-nullsafety.0 - Feb 24, 2021

-   **Breaking**:
    -   Opt into nullsafety.
    -   Set Dart SDK constraints to `>=2.12.0-0 <3.0.0`.
    -   Big refactoring for `Logger`, `RealRxStorage` implementation.

## 0.0.2 - Jan 4, 2021

-   Refactors `Storage` and `RxStorage`:
    -   Supports any type via `Encoder` and `Decoder`.
    -   Generic `Key` and generic `Options`.
-   Exports `RealRxStorage` class.

## 0.0.1 - Dec 14, 2020

-   Initial version.
