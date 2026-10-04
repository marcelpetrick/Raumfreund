// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

// Purpose: enforce the 100-physical-line limit for Dart functions (vision
// section 6, AGENTS.md section 5) with the analyzer AST.
// Usage:   dart run bin/check.dart [--max N] <path>...
// Exit codes: 0 ok, 1 violations found, 2 usage, missing path or parse error.

import 'dart:io';

import 'package:function_length/function_length.dart';

void main(List<String> args) {
  exitCode = run(args, stdout, stderr);
}
