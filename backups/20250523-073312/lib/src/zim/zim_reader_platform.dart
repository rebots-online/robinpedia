// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

// This file exports the appropriate ZIM reader implementation based on the platform
// It uses conditional imports to avoid importing dart:ffi on web platforms

export 'zim_reader_web.dart' if (dart.library.io) 'zim_reader_native.dart';
