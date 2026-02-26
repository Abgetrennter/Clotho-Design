---
name: clotho-flutter-state-management
description: Implement Flutter state management using Riverpod for Clotho's L0-L3 layered runtime architecture. Use when building UI components, managing session state, or integrating with Mnemosyne data engine in Code mode.
---

# Clotho Flutter 状态管理 (Clotho Flutter State Management)

## When to use this skill

Use this skill when:
- Creating or modifying Flutter UI components in `08_demo/` or future implementation
- Implementing state management with Riverpod for Clotho's layered architecture
- Building UI components that display or interact with Mnemosyne state (L3 Threads)
- Integrating UI with ClothoNexus event bus for state synchronization
- Implementing unidirectional data flow patterns (UI → Intent → State → UI)

## When NOT to use this skill

Do NOT use this skill when:
- Writing documentation (use `clotho-documentation-author` skill)
- Working on backend/core logic outside the presentation layer
- Managing state in non-Flutter contexts (e.g., pure Dart services)
- Designing UI layouts without state management concerns

## Inputs required from the user

- The component or feature to implement
- The state layer involved (L0/L1/L2/L3)
- Whether the component needs read-only or read-write access to state

## Architecture Context

### Layered Runtime Model

Clotho uses a 4-layer runtime architecture. UI interacts differently with each layer:

| Layer | Metaphor | Name | UI Access Pattern |
|-------|----------|------|-------------------|
| L0 | 骨架 | Infrastructure | Read-Only (Template, API Config) |
| L1 | 环境 | Environment | Read-Only (User Persona, Global Lore) |
| L2 | 织谱 | The Pattern | Read-Only (Character Card static data) |
| L3 | 丝络 | The Threads | **Read-Write** (State patches, History) |

### State Management Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (Riverpod)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ StateNotifier│  │  Provider   │  │ StreamProvider      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓ exposes as
┌─────────────────────────────────────────────────────────────┐
│                 Core Layer (GetIt)                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Repository  │  │  UseCase    │  │ Service (Mnemosyne) │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓ manages
┌─────────────────────────────────────────────────────────────┐
│              Data Layer (Mnemosyne)                          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  L0/L1/L2 (Read-Only)  │  L3 (Read-Write + OpLog)      ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Workflow

### 1. Determine the state layer

Identify which layer your component needs to access:

- **L0/L1/L2 (Read-Only)**: Use `Provider` or `FutureProvider` for static data
- **L3 (Read-Write)**: Use `StateNotifier` + `StateNotifierProvider` for mutable state
- **Stream-based updates**: Use `StreamProvider` for real-time state changes from ClothoNexus

### 2. Create the state class

For L3 mutable state, define a `StateNotifier`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State class
class TapestryState {
  final List<Thread> threads;
  final Pattern activePattern;
  final Punchcard? currentPunchcard;
  
  const TapestryState({
    required this.threads,
    required this.activePattern,
    this.currentPunchcard,
  });
  
  TapestryState copyWith({
    List<Thread>? threads,
    Pattern? activePattern,
    Punchcard? currentPunchcard,
  }) {
    return TapestryState(
      threads: threads ?? this.threads,
      activePattern: activePattern ?? this.activePattern,
      currentPunchcard: currentPunchcard ?? this.currentPunchcard,
    );
  }
}

// StateNotifier
class TapestryNotifier extends StateNotifier<TapestryState> {
  final MnemosyneRepository _mnemosyne;
  
  TapestryNotifier(this._mnemosyne) : super(
    TapestryState(threads: [], activePattern: Pattern.empty),
  );
  
  Future<void> loadTapestry(String patternId) async {
    final pattern = await _mnemosyne.getPattern(patternId);
    state = state.copyWith(activePattern: pattern);
  }
  
  Future<void> appendThread(Thread thread) async {
    await _mnemosyne.appendThread(thread);
    state = state.copyWith(threads: [...state.threads, thread]);
  }
  
  Future<void> applyPunchcard(Punchcard punchcard) async {
    await _mnemosyne.applyPatch(punchcard);
    state = state.copyWith(currentPunchcard: punchcard);
  }
}

// Provider
final tapestryProvider = StateNotifierProvider<TapestryNotifier, TapestryState>(
  (ref) => TapestryNotifier(ref.watch(mnemosyneRepositoryProvider)),
);
```

### 3. Implement unidirectional data flow

Follow the **Intent → State → UI** pattern:

```dart
// 1. UI emits Intent (not direct state mutation)
class SendMessageIntent {
  final String content;
  final Map<String, dynamic>? metadata;
  
  const SendMessageIntent({
    required this.content,
    this.metadata,
  });
}

// 2. UseCase handles the intent
class SendMessageUseCase {
  final JacquardOrchestrator _orchestrator;
  final MnemosyneRepository _mnemosyne;
  
  Future<void> execute(SendMessageIntent intent) async {
    // Create Thread from intent
    final thread = Thread.userMessage(
      content: intent.content,
      timestamp: DateTime.now(),
    );
    
    // Append to Mnemosyne (L3)
    await _mnemosyne.appendThread(thread);
    
    // Trigger Jacquard pipeline
    await _orchestrator.processTurn(thread);
  }
}

// 3. UI observes state changes via Stream
@override
Widget build(BuildContext context, WidgetRef ref) {
  final tapestryState = ref.watch(tapestryProvider);
  
  return ListView.builder(
    itemCount: tapestryState.threads.length,
    itemBuilder: (context, index) {
      final thread = tapestryState.threads[index];
      return ThreadWidget(thread: thread);
    },
  );
}
```

### 4. Integrate with ClothoNexus event bus

For cross-component state synchronization:

```dart
// Subscribe to state change events
class TapestrySyncService {
  final ClothoNexus _nexus;
  final StateNotifier<TapestryState> _notifier;
  
  TapestrySyncService(this._nexus, this._notifier) {
    _nexus.subscribe<ThreadAppendedEvent>((event) {
      _notifier.state = _notifier.state.copyWith(
        threads: [..._notifier.state.threads, event.thread],
      );
    });
    
    _nexus.subscribe<PunchcardAppliedEvent>((event) {
      _notifier.state = _notifier.state.copyWith(
        currentPunchcard: event.punchcard,
      );
    });
  }
}
```

### 5. Handle L3 state patching

L3 (Threads) is the only read-write layer. Implement efficient patching:

```dart
// Sparse snapshot + OpLog approach
class L3StatePatcher {
  final MnemosyneRepository _mnemosyne;
  
  /// Apply incremental state changes
  Future<void> applyPatch(StatePatch patch) async {
    // 1. Validate patch against current state
    final currentState = await _mnemosyne.getL3State();
    
    // 2. Create OpLog entry
    final opLog = OpLog(
      operation: patch.operation,
      path: patch.path,
      value: patch.value,
      timestamp: DateTime.now(),
    );
    
    // 3. Apply to in-memory state
    final newState = currentState.applyOpLog([opLog]);
    
    // 4. Persist OpLog (not full state)
    await _mnemosyne.appendOpLog(opLog);
    
    // 5. Broadcast change
    ClothoNexus.instance.broadcast(L3StateChangedEvent(newState));
  }
}
```

## Key Components

### StateNotifier Providers

| Provider | Layer | Access | Purpose |
|----------|-------|--------|---------|
| `patternProvider` | L2 | Read-Only | Static character/preset data |
| `tapestryProvider` | L3 | Read-Write | Active session state |
| `environmentProvider` | L1 | Read-Only | User persona, global lore |
| `infrastructureProvider` | L0 | Read-Only | Templates, API config |

### Event Types

| Event | Layer | Trigger |
|-------|-------|---------|
| `ThreadAppendedEvent` | L3 | New message added |
| `PunchcardAppliedEvent` | L3 | State snapshot applied |
| `PatternLoadedEvent` | L2 | Character card loaded |
| `LorebookUpdatedEvent` | L1 | Global lore changed |

## Code Generation Templates

### Basic StateNotifier Template

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State
class ${NAME}State {
  // TODO: Define state fields
  
  const ${NAME}State();
  
  ${NAME}State copyWith({
    // TODO: Add copyWith parameters
  }) {
    return ${NAME}State(
      // TODO: Implement copyWith
    );
  }
}

// Notifier
class ${NAME}Notifier extends StateNotifier<${NAME}State> {
  ${NAME}Notifier() : super(const ${NAME}State());
  
  // TODO: Add state mutation methods
}

// Provider
final ${name}Provider = StateNotifierProvider<${NAME}Notifier, ${NAME}State>(
  (ref) => ${NAME}Notifier(),
);
```

## Troubleshooting

### State not updating in UI
- Ensure you're using `ref.watch()` to subscribe to the provider
- Check that `copyWith()` creates a new instance (not mutating state)
- Verify the StateNotifier calls `state = newState` after mutations

### Circular dependency errors
- Use `ref.read()` for one-time reads inside callbacks
- Use `ref.watch()` only in build methods and provider declarations
- Consider using `AsyncNotifier` for complex async operations

### Performance issues with large state
- Use `select()` to listen to specific fields: `ref.watch(tapestryProvider.select((s) => s.threads.length))`
- Consider splitting large state into multiple providers
- Implement lazy loading for L3 state (load only visible threads)

### L3 state inconsistency
- Always use OpLog for L3 mutations (not direct state replacement)
- Ensure ClothoNexus events are broadcast after state changes
- Implement state reconciliation on app resume

## Related Documents

- [`00_active_specs/runtime/layered-runtime-architecture.md`](00_active_specs/runtime/layered-runtime-architecture.md) - L0-L3 architecture details
- [`00_active_specs/mnemosyne/README.md`](00_active_specs/mnemosyne/README.md) - Data engine overview
- [`00_active_specs/presentation/README.md`](00_active_specs/presentation/README.md) - Presentation layer design
- [`00_active_specs/infrastructure/clotho-nexus-events.md`](00_active_specs/infrastructure/clotho-nexus-events.md) - Event bus specification
