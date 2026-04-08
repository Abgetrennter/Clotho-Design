import 'package:clotho_v1_app/app/clotho_app.dart';
import 'package:clotho_v1_app/bootstrap/app_bootstrap.dart';
import 'package:clotho_v1_app/bootstrap/environment_config.dart';
import 'package:clotho_v1_app/bootstrap/service_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell renders V1 destinations', (tester) async {
    const environment = EnvironmentConfig(
      appName: 'Clotho Test',
      enableDiagnostics: true,
      defaultSessionTitle: 'Test Session',
    );
    final registry = ServiceRegistry.bootstrap(environment);
    final bootstrap = BootstrapResult(
      environment: environment,
      registry: registry,
    );

    await tester.pumpWidget(ClothoApp(bootstrap: bootstrap));
    await tester.pumpAndSettle();

    expect(find.text('Stage'), findsWidgets);
    expect(find.text('Inspector'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}
