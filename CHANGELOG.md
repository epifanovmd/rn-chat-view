# Changelog

Фиксация изменений API, моделей и публичных интерфейсов.

## 2026-04-03

### Delegate

- **`chatDidTapFAB()`** — новый метод делегата
  - Всегда вызывается при нажатии на FAB-кнопку
  - Хост-приложение полностью управляет реакцией на нажатие (скролл, сброс счётчика и т.д.)

### Behavior

- **`setUnreadCount(_:)`** — новый метод, переключает FAB в режим внешнего управления
  - При первом вызове устанавливает `isExternalUnreadManagement = true`
  - Внутренний подсчёт (`trackNewUnread`) и декремент при появлении сообщений отключаются
  - Нажатие FAB только вызывает `chatDidTapFAB()` — хост сам решает что делать
  - Для управления счётчиком: `setUnreadCount(N)`, `clearUnread()`
  - `scrollToBottom(animated:)` вызывается хостом напрямую
- **Внутренний режим** (если `setUnreadCount` не вызывался):
  - Счётчик пополняется автоматически при получении новых сообщений (`trackNewUnread`)
  - Счётчик уменьшается при появлении непрочитанных сообщений на экране (скролл вниз)
  - FAB **не** сбрасывает счётчик при скрытии — только видимость сообщений
  - Нажатие FAB: `chatDidTapFAB()` (хост управляет)

### Voice Recording

- **`chatDidCompleteVoiceRecording(fileURL:duration:waveform:)`** — добавлен параметр `waveform: [Float]`
  - Массив нормализованных уровней громкости (0…1), собранных во время записи с частотой 15–30 fps
  - `VoiceRecorder` собирает сэмплы автоматически через `AVAudioRecorder.averagePower`
  - Хост получает готовый waveform и может использовать его напрямую в `VoicePayload`
- **`VoiceRecorderDelegate.voiceRecorderDidStop(fileURL:duration:waveform:)`** — аналогично добавлен `waveform`

### Models

- **`PollPayload`** — добавлено поле `isAnonymous: Bool`
  - Управляет видимостью кнопки "Результаты" в опросе
  - В `ChatParsing` default = `true` (анонимный) для обратной совместимости

## 2026-04-02

### Build

- `ENABLE_USER_SCRIPT_SANDBOXING = NO` — необходимо для CocoaPods
- `NSMicrophoneUsageDescription` — добавлен в Info.plist (Debug + Release)
