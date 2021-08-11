import 'dart:io' show Platform;

void main() {
  // Get the operating system as a string.
  String os = Platform.operatingSystem;
  // Or, use a predicate getter
  if (Platform.isMacOS) {
    print('is a Mac');
  } else {
    print('is not a Mac');
  }
}