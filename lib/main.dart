import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/providers/service_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ShaqoNetEmployeeBootstrap()));
}

class ShaqoNetEmployeeBootstrap extends ConsumerWidget {
  const ShaqoNetEmployeeBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapProvider);

    return bootstrap.when(
      data: (_) => const ShaqoNetEmployeeApp(),
      loading: () => const _BootstrapShell(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => _BootstrapShell(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error is AppConfigException
                ? error.message
                : 'ShaqoNet could not start. Check the mobile app configuration.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _BootstrapShell extends StatelessWidget {
  const _BootstrapShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }
}
