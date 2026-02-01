// lib/services/riverpod_imports.dart
// Κεντρικό σημείο εισαγωγής Riverpod 3.0 με υποστήριξη legacy providers.
//
// Σημείωση: Δεν κάνουμε "hide ..." γιατί στο Riverpod 3 οι legacy providers
// δεν εξάγονται καν από το flutter_riverpod.dart — άρα το hide έσπαγε.

export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:flutter_riverpod/legacy.dart'
    show ChangeNotifierProvider, StateProvider, StateNotifierProvider;
