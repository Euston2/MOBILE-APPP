/// Foreground time for a single app, in whole seconds.
class AppUsage {
  const AppUsage({required this.packageName, required this.seconds});

  final String packageName;
  final int seconds;

  @override
  String toString() => 'AppUsage($packageName, ${seconds}s)';
}
