import 'package:flutter/material.dart';

import '../bootstrap/app_bootstrap.dart';
import '../shared/theme/app_theme.dart';
import '../shared/theme/design_tokens.dart';
import '../shared/widgets/app_section_card.dart';
import 'app_providers.dart';
import 'app_router.dart';

class ClothoApp extends StatefulWidget {
  const ClothoApp({required this.bootstrap, super.key});

  final BootstrapResult bootstrap;

  @override
  State<ClothoApp> createState() => _ClothoAppState();
}

class _ClothoAppState extends State<ClothoApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _appState,
      child: MaterialApp(
        title: widget.bootstrap.environment.appName,
        debugShowCheckedModeBanner: false,
        theme: ClothoTheme.lightTheme,
        darkTheme: ClothoTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: AppShell(appName: widget.bootstrap.environment.appName),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.appName, super.key});

  final String appName;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final destination = appState.destination;
        final page = buildDestinationScreen(destination);

        return LayoutBuilder(
          builder: (context, constraints) {
            final wideLayout = constraints.maxWidth >= 900;

            if (wideLayout) {
              return Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      extended: constraints.maxWidth >= 1240,
                      selectedIndex: AppDestination.values.indexOf(destination),
                      onDestinationSelected: (index) {
                        appState.selectDestination(
                          AppDestination.values[index],
                        );
                      },
                      leading: Padding(
                        padding: const EdgeInsets.only(
                          top: SpacingTokens.lg,
                          left: SpacingTokens.sm,
                          right: SpacingTokens.sm,
                        ),
                        child: _AppMark(appName: appName),
                      ),
                      destinations: [
                        for (final item in AppDestination.values)
                          NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: Text(item.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(SpacingTokens.lg),
                          child: page,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(title: Text(appName)),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  child: page,
                ),
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: AppDestination.values.indexOf(destination),
                destinations: [
                  for (final item in AppDestination.values)
                    NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                ],
                onDestinationSelected: (index) {
                  appState.selectDestination(AppDestination.values[index]);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark({required this.appName});

  final String appName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSectionCard(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(appName, style: theme.textTheme.titleMedium),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'V1 skeleton for Presentation, Jacquard, Mnemosyne, and Muse integration.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
