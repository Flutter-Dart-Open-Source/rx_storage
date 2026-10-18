# Stream timeline image prompt

Generated with the built-in imagegen tool. Final asset: `stream-timeline.png`.

## Initial prompt

```text
Use case: infographic-diagram
Asset type: README documentation diagram for the Dart package rx_storage, replacing a plain ASCII timeline. Create one finished high-resolution landscape raster image, approximately 1800 x 1000 pixels, on an opaque white background.
Primary request: Make the existing reactive stream timeline clear, precise, and elegant for software developers. Keep this as a horizontal event timeline, not a flowchart.
Style: polished technical editorial infographic, flat vector-like shapes rendered as a bitmap, clean typography, restrained teal accent for the observed key and its stream, neutral gray for unrelated key changes. Strong contrast, generous whitespace, clean alignment. Readable at about 850 pixels wide. All labels in English. No decorative illustrations.
Title at top left: "Observing a single key"
Small code-style subtitle directly underneath: "observe(K1)"
Main layout: two horizontal lanes on a shared left-to-right time axis. The upper lane is labeled "Storage changes". The lower lane is labeled "Returned Stream". Keep the left label column separate from all events.
A vertical dashed subscription marker near the beginning of the plot is labeled "Listen to K1". The lower stream starts at this marker, while the upper storage timeline extends from before it.
Initial read: after the subscription marker and before the first storage change, place one teal circular emission marker containing "@" on the lower lane, with the label "Initial read" underneath. There is no storage-change event above this initial marker. Show a small horizontal gap between subscription and this initial emission; do not imply synchronous delivery.
Upper lane events, in this EXACT left-to-right order, five total, with spacious equal-ish gaps: "K1", "K2", "K1", "K1", "K2". Put each label inside a rounded pill sitting on the upper lane. All three K1 pills are teal; both K2 pills are gray.
Correspondence: each of the three K1 events has exactly one thin teal vertical arrow leading down to exactly one teal circular "@" emission marker on the lower lane, aligned below that K1 event. End each arrow at the top edge of its lower marker. The two K2 events have no downward arrows and no lower emission markers. Preserve blank gaps on the lower lane at the K2 positions. Do not add any other events.
Lower lane has exactly FOUR emission markers in order: the initial read, the first K1 change, the second K1 change, the third K1 change. There must be no emission before subscription. All four circles contain the single character "@".
At the right of the timelines include a small "time" label with a rightward arrow.
Bottom annotation, clearly separated from the plot: "@ = nullable value or TypeError"
Second short annotation: "K2 changes do not emit on this stream."
Constraints: The event counts, chronological order, and exact correspondences above are essential. Use crisp large labels, ample padding, straight lanes, no crossings, no overlapping text, no tiny labels, no gradients, no 3D, no textures, no watermark, no logos, no invented extra words. The goal is the same meaning as the original ASCII diagram, with a more readable visual hierarchy.
```

## Refinement prompt

The first draft misaligned the initial read and connected a K2 change to an emission. Apply this edit to correct the chart while preserving its appearance.

```text
Edit target: the attached rx_storage timeline infographic.
Use case: infographic-diagram.
Keep the white background, typography, title, subtitle, lane labels, legend, teal/gray palette, and overall landscape composition.
Correct ONLY the event layout and arrow correspondences. The present image is logically wrong because it places the first K1 change directly above Initial read and draws an emission arrow from K2.

Rebuild the chart area using SIX aligned time columns, starting after the dashed Listen to K1 marker. Make room by using slightly smaller event pills and slightly more compact spacing. Use this EXACT alignment table:

COLUMN                 1             2          3         4         5         6
UPPER STORAGE LANE     EMPTY         K1         K2        K1        K1        K2
LOWER STREAM LANE      @             @          EMPTY     @         @         EMPTY
VERTICAL ARROW         NONE          YES        NONE      YES       YES       NONE
LABEL BELOW            Initial read

Here EMPTY means the plain timeline passes through with NO pill, NO dot, NO marker, NO label, and NO arrow.
Column 1 is the earliest event after subscribing. It must contain a lower initial emission only, and have NO upper key change above it.
Columns 2, 4, and 5 each contain a teal K1 pill, a thin teal downward arrow, and a teal @ marker directly below.
Columns 3 and 6 each contain only a gray K2 pill on the upper lane. The lower lane at both those positions MUST be plain empty line. No downward arrow may originate from any K2 pill.
Exactly FIVE upper pills, in order K1 K2 K1 K1 K2.
Exactly FOUR lower @ markers, in columns 1, 2, 4, and 5.
Exactly THREE downward arrows, all originating from K1 pills.
The Listen to K1 dashed vertical line is before column 1. The initial @ is AFTER that line and BEFORE the first upper K1 pill in time.
Preserve all existing title and legend text verbatim.
Flat opaque white background, no textures or shading, sharp technical rendering.
```
