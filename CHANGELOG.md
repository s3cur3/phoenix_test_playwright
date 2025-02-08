# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] 2025-02-03
### Added
- Screenshots: `screenshot/{2,3}` function and `screenshot: true` config for auto-capture
- Pass browser config via `Case` opts, e.g. `use PhoenixTest.Playwright.Case, headless: false`

### Changed
- Renamed: `PheonixTest.Case` to `PhoenixTest.Playwright.Case`
  ```diff
     defmodule MyTest do
  -    use PhoenixTest.Case, async: true
  +    use PhoenixTest.Playwright.Case, async: true
  -    @moduletag :playwright
  ```

### Changed
- Config: flattened list (remove nested `browser` config), override via top-level ExUnit `@tag ...`s (remove nested `@tag playwright: [...]`)
  ```diff
     # config/test.exs
     config :phoenix_test,
       playwright: [
  -      browser: [browser: :chromium, headless: false, slow_mo: 0]
  +      browser: :chromium,
  +      headless: false,
  +      slow_mo: 0
  ```

## [0.3.0] 2025-01-26
### Changed
- Auto-convert case of playwright messages keys (snake_case to camelCase)

## [0.2.1] 2025-01-17
### Added
- Add more config options (browser, JS console) @s3cur3

### Changed
- Improve error messages @s3cur3
- Improve setup and docs for contributors @s3cur3

## [0.2.0] 2025-01-09
### Added
- support `phoenix_test@0.5`, `elixir@1.18`, `phoenix_live_view@1.0`

## [0.1.5] 2024-12-15
### Added
- `@tag trace: :open` to auto open recorded Playwright trace in viewer
