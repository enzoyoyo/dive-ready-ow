# Content schema

`Resources/StudyCatalog.json` is decoded as schema version 2 by `CatalogLoader`.

Each course may contain:

- `id`, `chapter`, `title`, `summary`, `durationMinutes` and `isCritical` for navigation and pacing.
- `validationStage`: `explainOnly`, `instructorCheck` or `inWaterValidation`.
- `keyPoints` for short reading cards.
- `frames` for optional image-backed explanations. `imageName` and `timestampLabel` may be `null`.
- `clips` for optional local media. A clip must declare a file name, source range, safety level and safety boundary.
- `source` with a human-readable locator and structured references.

Questions must point to an existing course, contain exactly three unique choices and identify one correct choice. In schema version 2 they also declare `sourceEvidence` so readers can distinguish current references from instructor verification.

`quickReferences` are short checklists. `emergencyContacts` is empty in the public demo; if you add local entries, verify them against current local official sources and do not publish private contact data.

The loader validates uniqueness, relationships, source references and clip ranges. It does not certify the content or decide whether a person is fit to dive.
