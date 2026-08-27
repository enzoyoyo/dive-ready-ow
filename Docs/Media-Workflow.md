# Local media workflow

The app can play short local clips and show selected frames, but the public repository intentionally ships without personal or course-specific media.

## Prepare a clip

1. Confirm the source license allows local use and, if applicable, redistribution.
2. Trim to the smallest teaching segment and keep the original source and time range in your private notes.
3. Export an iOS-friendly H.264/AAC or HEVC/AAC file. Keep the audio track when narration is required.
4. Remove metadata that can reveal a person, GPS location, device or recording session. Check the visual frames for names, badges and documents.
5. Test the clip on a simulator and a real device before relying on it offline.

## Register it

Put the file in the local `Resources/Media/` folder. Add a matching `clips` entry to `StudyCatalog.json` with:

- a stable `id` and local `fileName`;
- `sourceVideo`, `sourceStartSeconds` and `sourceEndSeconds`;
- `safetyLevel` and a plain-language `safetyBoundary`;
- an optional poster and a source citation.

Do not claim that a clip was reviewed against a course or instructor unless you have evidence to support that claim. The app's completion state only records local reading/playback; it never changes an official training record.
