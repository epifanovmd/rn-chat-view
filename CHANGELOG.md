# Changelog

Фиксация изменений API, моделей и публичных интерфейсов.

## 2026-04-03

### Models

- **`PollPayload`** — добавлено поле `isAnonymous: Bool`
  - Управляет видимостью кнопки "Результаты" в опросе
  - В `ChatParsing` default = `true` (анонимный) для обратной совместимости

## 2026-04-02

### Build

- `ENABLE_USER_SCRIPT_SANDBOXING = NO` — необходимо для CocoaPods
- `NSMicrophoneUsageDescription` — добавлен в Info.plist (Debug + Release)
