# Timeblock

Native macOS 14+ menu bar app (SwiftUI + AppKit, SwiftData). See README.md for build steps and layout.

## Source of truth

The GitHub repository https://github.com/karlschneidewind/timeblock is the single source of truth. Always work in a clone of it, never in a loose copy of the files.

## GitHub workflow

- Before starting work, pull the latest `main`.
- Make each change on a short-lived branch (`feature/…`, `fix/…`) and merge it to `main` with a pull request.
- Keep commits small and focused, and write messages in the imperative ("Add …", "Fix …").
- Make sure the project builds before committing or pushing.
- Never commit build output, `xcuserdata`, `.DS_Store` or secrets (see `.gitignore`).
- Update README.md when behavior, setup or file layout changes.

## Project notes

- `Timeblock.xcodeproj` is generated from `project.yml` (XcodeGen). Run `xcodegen generate` after adding or removing files.
- Build check: `xcodebuild -project Timeblock.xcodeproj -scheme Timeblock -configuration Debug -derivedDataPath build build`
- Follow Apple's macOS Human Interface Guidelines: system text styles, semantic colors, VoiceOver labels, and keyboard or menu alternatives for gestures.
