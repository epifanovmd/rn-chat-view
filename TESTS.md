# Тесты IOSChatView

**Всего:** 58 тестов (45 интеграционных + 13 unit)

## Интеграционные тесты

Фреймворк: Swift Testing (`@Suite` / `@Test`), запуск на устройстве.
Расположение: `Example/rn-chat-view-tests/`

```bash
cd Example
xcodebuild test -workspace rn-chat-view.xcworkspace \
  -scheme rn-chat-view \
  -destination 'id=00008110-000C0CA03A21801E' \
  -allowProvisioningUpdates \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  -only-testing:'rn-chat-view-tests'
```

### Кейс 1: Первоначальная загрузка
| # | Тест | Файл |
|---|------|------|
| 1 | сообщения появляются и скролл внизу | Case01_InitialLoadTests.swift |
| 2 | высоты лейаута вычислены для всех строк | Case01_InitialLoadTests.swift |

### Кейс 2: Очистка всех сообщений
| # | Тест | Файл |
|---|------|------|
| 1 | очистка удаляет все сообщения и строки | Case02_ClearTests.swift |

### Кейс 3: Подгрузка старых сообщений (Prepend)
| # | Тест | Файл |
|---|------|------|
| 1 | смещение скролла компенсируется — пользователь остаётся на месте | Case03_PrependTests.swift |
| 2 | количество сообщений увеличивается | Case03_PrependTests.swift |

### Кейс 4: Добавление новых сообщений (Append, пагинация)
| # | Тест | Файл |
|---|------|------|
| 1 | скролл остаётся на месте (НЕ прыгает вниз) | Case04_AppendPaginationTests.swift |

### Кейс 5: Сокет-сообщение при скролле внизу
| # | Тест | Файл |
|---|------|------|
| 1 | количество сообщений увеличивается на 1 | Case05_SocketAtBottomTests.swift |

### Кейс 6: Сокет-сообщение при прокрутке вверх
| # | Тест | Файл |
|---|------|------|
| 1 | скролл остаётся вверху при добавлении нового сообщения | Case06_SocketScrolledUpTests.swift |

### Кейс 7: Обновление содержимого (ContentOnly)
| # | Тест | Файл |
|---|------|------|
| 1 | высота меняется при удлинении текста | Case07_ContentUpdateTests.swift |
| 2 | обновление внизу: скролл остаётся внизу при увеличении высоты | Case07_ContentUpdateTests.swift |
| 3 | обновление внизу: скролл остаётся внизу при уменьшении высоты | Case07_ContentUpdateTests.swift |
| 4 | обновление выше вьюпорта: нижние ячейки не сдвигаются | Case07_ContentUpdateTests.swift |
| 5 | обновление выше вьюпорта: смещение сдвигается вверх, а не вниз | Case07_ContentUpdateTests.swift |
| 6 | обновление внизу: нет прыжка скролла при добавлении реакции | Case07_ContentUpdateTests.swift |

### Кейс 8: Ожидающее → реальное (подтверждение отправки)
| # | Тест | Файл |
|---|------|------|
| 1 | pendingMapping: обнаруживает маппинг по localId | Case08_PendingToRealTests.swift |
| 2 | нет маппинга когда localId равен nil | Case08_PendingToRealTests.swift |
| 3 | нет маппинга когда localId различаются | Case08_PendingToRealTests.swift |
| 4 | количество сообщений не меняется после pending→real с localId | Case08_PendingToRealTests.swift |
| 5 | содержимое сообщения обновляется после pending→real | Case08_PendingToRealTests.swift |
| 6 | количество сообщений не меняется после замены (без localId) | Case08_PendingToRealTests.swift |

### Кейс 9: Удаление сообщения
| # | Тест | Файл |
|---|------|------|
| 1 | количество сообщений уменьшается | Case09_DeleteTests.swift |
| 2 | скролл сохраняется после удаления в середине | Case09_DeleteTests.swift |

### Кейс 10: Удаление + обновление одновременно
| # | Тест | Файл |
|---|------|------|
| 1 | оба изменения применяются | Case10_DeleteAndUpdateTests.swift |

### Кейс 11: Массовое удаление
| # | Тест | Файл |
|---|------|------|
| 1 | размер контента уменьшается | Case11_MassDeleteTests.swift |

### Кейс 20: Обновление содержимого при прокрутке вверх
| # | Тест | Файл |
|---|------|------|
| 1 | скролл остаётся на месте при редактировании выше | Case20_ContentUpdateDetachedTests.swift |

### Кейс 21: Пакетные сокет-события
| # | Тест | Файл |
|---|------|------|
| 1 | пакет изменений применяется корректно | Case21_BatchSocketTests.swift |

### Кейс 22: Удаление + вставка одновременно (замена)
| # | Тест | Файл |
|---|------|------|
| 1 | количество сообщений не меняется | Case22_DeleteAndInsertTests.swift |
| 2 | скролл сохраняется при замене сообщения той же высоты в середине | Case22_DeleteAndInsertTests.swift |
| 3 | скролл сохраняется при замене на более короткое сообщение | Case22_DeleteAndInsertTests.swift |
| 4 | скролл сохраняется при замене на более высокое сообщение | Case22_DeleteAndInsertTests.swift |
| 5 | удаление последнего + вставка на то же место: остаётся внизу | Case22_DeleteAndInsertTests.swift |
| 6 | удаление + вставка выше вьюпорта сохраняет скролл | Case22_DeleteAndInsertTests.swift |

### Кейс 23: Стабильность скролла при разных операциях
| # | Тест | Файл |
|---|------|------|
| 1 | реакция внизу: первый раз — скролл не прыгает | Case23_ScrollStabilityTests.swift |
| 2 | реакция внизу: повторно — скролл не прыгает | Case23_ScrollStabilityTests.swift |
| 3 | edit+ внизу: скролл остаётся внизу | Case23_ScrollStabilityTests.swift |
| 4 | edit- внизу: скролл остаётся внизу | Case23_ScrollStabilityTests.swift |
| 5 | edit выше viewport: нижние ячейки не смещаются | Case23_ScrollStabilityTests.swift |
| 6 | edit в середине: якорная ячейка не смещается | Case23_ScrollStabilityTests.swift |
| 7 | удаление в viewport: остаёмся на месте | Case23_ScrollStabilityTests.swift |
| 8 | удаление выше viewport: видимые ячейки не смещаются | Case23_ScrollStabilityTests.swift |
| 9 | вставка выше viewport: видимые ячейки не смещаются | Case23_ScrollStabilityTests.swift |
| 10 | вставка внизу при wasAtBottom: остаёмся внизу | Case23_ScrollStabilityTests.swift |
| 11 | del+ins на одной позиции: скролл не прыгает | Case23_ScrollStabilityTests.swift |
| 12 | prepend: видимые ячейки не смещаются | Case23_ScrollStabilityTests.swift |
| 13 | pendingScrollToBottom + скролл вверх + реакция: не бросает вниз | Case23_ScrollStabilityTests.swift |

---

## Unit-тесты

Фреймворк: XCTest.
Расположение: `Example/Tests/MessageDiffTests.swift`

### MessageDiffPatternTests — паттерны isPrependOnly / isAppendOnly
| # | Тест |
|---|------|
| 1 | testIsPrependOnly_true |
| 2 | testIsPrependOnly_false_shuffled |
| 3 | testIsPrependOnly_false_sameCount |
| 4 | testIsAppendOnly_true |
| 5 | testIsAppendOnly_false_shuffled |
| 6 | testIsAppendOnly_false_sameCount |
| 7 | testPrependBatch |
| 8 | testAppendBatch |

### MessageDiffPendingMappingTests — маппинг pending→real
| # | Тест |
|---|------|
| 1 | testPendingToReal_withLocalId |
| 2 | testNoMapping_withoutLocalId |
| 3 | testNoMapping_differentLocalId |
| 4 | testNoMapping_sameIdStays |
| 5 | testMultiplePendingMappings |

---

## Вспомогательные файлы

| Файл | Описание |
|------|----------|
| `ChatTestHelper.swift` | Хелпер для интеграционных тестов: создание ChatViewController, генерация сообщений, проверка scroll stability (`screenY(forMessageId:)`), ожидание layout |
| `rn_chat_view_tests.swift` | Точка входа тестового таргета |
