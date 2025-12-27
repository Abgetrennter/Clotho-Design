# ST-Prompt-Template Integration Analysis & Plan

## 1. Project Structure Analysis
The `neuropean` project follows a **Clean Architecture** pattern, structured by features (`features/chat`, `features/character`) and core abstractions (`core/abstraction`).

-   **`features/chat`**: Contains the core logic for messaging.
    -   `domain/entities/chat_message.dart`: The fundamental message unit.
    -   `domain/orchestrator/orchestrator.dart`: The central brain managing the message flow. This is currently a mock implementation (`MockOrchestrator`) but is the correct place for pipeline logic.
    -   `presentation/providers/chat_provider.dart`: Uses Riverpod (`StateProvider`) to manage UI state.
-   **`features/character`**: Handles character data.
    -   `data/models/character_card_model.dart`: Contains the `CharacterCardModel` which includes the `characterBook` field. This `characterBook` maps directly to the "World Info" concept in the source plugin.

## 2. Integration Points
The optimal integration strategy is to inject the logic into the **Domain Layer** of the Chat feature, specifically within the Orchestrator's pipeline.

*   **Prompt Generation**: `lib/features/chat/domain/orchestrator/orchestrator.dart`
    *   *Current:* Simple pass-through of user input to a mock stream.
    *   *Target:* Must intercept the message list *before* sending to the (future) LLM API.
*   **Message Processing**: `PromptInjectionService` (New)
    *   Will reside in `lib/features/chat/domain/services/`.
    *   Responsible for parsing `@INJECT` tags and manipulating the `List<ChatMessage>`.
*   **Variable Management**: `VariableManager` (New)
    *   Will reside in `lib/features/chat/domain/services/`.
    *   Responsible for holding global/chat state (replacing `variables.ts`).

## 3. Extension Mechanisms
The current architecture does not support dynamic plugin loading (like JavaScript `eval`). Therefore, the `ST-Prompt-Template` logic must be **ported to Dart** and embedded directly into the application core.
*   **Mechanism**: Service Injection. The `Orchestrator` will depend on a `PromptInjectionService`.
*   **Configurability**: We will map the `characterBook` entries from the `CharacterCardModel` to the injection logic.

## 4. State Management (Riverpod)
Riverpod is used for dependency injection and state management.
*   **Global State**: Variables that persist across chats (if any) should be managed by a `StateNotifierProvider`.
*   **Chat State**: The active `VariableManager` instance should be scoped to the current chat session, likely provided alongside the `Orchestrator`.

## 5. Implementation Plan (Todo List)

### Phase 1: Core Logic Porting
1.  **Data Models**: Create Dart classes for `InjectionRule` (parsed from `@INJECT` comments).
2.  **Variable Manager**: Port `variables.ts` to Dart class `VariableManager`.
3.  **Template Engine**: Implement basic string substitution (`{{user}}`, `{{char}}`) to support prompt content.

### Phase 2: Injection Service
1.  **Regex Parsing**: Implement the parser for `role=...`, `pos=...`, `target=...`, `regex=...`.
2.  **Strategies**: Implement the three insertion strategies:
    *   *Position-based*: Absolute index insertion.
    *   *Target-based*: Relative to specific roles/messages.
    *   *Regex-based*: Triggered by content patterns.

### Phase 3: Orchestrator Integration
1.  **Wire up**: Inject `PromptInjectionService` into `Orchestrator`.
2.  **Pipeline**: Update `processUserMessage` to:
    *   Take current history.
    *   Run `PromptInjectionService.process(history, characterBook)`.
    *   Use the *modified* history for the actual LLM generation (simulated).

### Phase 4: Testing
1.  **Unit Tests**: robust testing of the injection logic using the JSON test cases from the original repo.