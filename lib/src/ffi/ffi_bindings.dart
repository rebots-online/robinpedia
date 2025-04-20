// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

// This file exports the appropriate FFI bindings based on the platform
// It uses conditional imports to avoid importing dart:ffi on web platforms

export 'ffi_bindings_stub.dart' if (dart.library.io) 'ffi_bindings_native.dart';
