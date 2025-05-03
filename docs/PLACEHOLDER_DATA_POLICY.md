# Placeholder Data Policy

**Date**: May 3, 2025  
**Author**: Robin L. M. Cheung, MBA  
**Copyright**: (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

## Overview

This document establishes the official policy for using placeholder data within the Robinpedia project. Placeholder data refers to any hard-coded, sample, or mock data used in place of real data that would normally be retrieved from an API, database, or other external source.

## Core Principles

1. **Explicit Authorization**: Placeholder data must be explicitly authorized and documented.
2. **Temporary by Design**: All placeholder data must be designed as a temporary solution with a clear path to removal.
3. **Visibility**: Placeholder data must be clearly visible in the codebase and to users of the application.
4. **Tracking**: All placeholder data must be tracked in the project's issue tracking system.
5. **Minimal Scope**: Placeholder data should be limited to the smallest possible scope needed.

## Implementation Guidelines

### When Placeholder Data Is Permitted

Placeholder data is permitted only in the following circumstances:

1. **Early Development**: During initial feature development before APIs are available.
2. **Testing**: For unit tests, integration tests, and UI tests.
3. **Demos**: For demonstration purposes when real data cannot be guaranteed.
4. **Fallback**: As a last-resort fallback when all attempts to retrieve real data have failed.

### Required Documentation

All placeholder data must be documented with:

1. **Source Code Comments**: Clear comments in the code indicating:
   - That the data is placeholder data
   - The issue/ticket tracking its removal
   - The conditions under which it is used
   - The expected timeline for removal

2. **Issue Tracking**: Each instance of placeholder data must have a corresponding issue in the project tracking system with:
   - Description of the placeholder data
   - Reason for its use
   - Acceptance criteria for its removal
   - Target date for removal
   - Assigned owner

3. **User Visibility**: When placeholder data is displayed to users, it must be clearly marked as such.

### Implementation Pattern

All placeholder data should follow this implementation pattern:

```dart
// PLACEHOLDER DATA: Issue #123 - Remove by 2025-06-01
// This placeholder data is used when the API call fails
// and will be removed once error handling is improved.
List<Item> _getPlaceholderItems() {
  debugPrint('WARNING: Using placeholder data - see Issue #123');
  return [
    // Placeholder items...
  ];
}
```

### Tracking Mechanism

1. **Placeholder Registry**: A central registry file (`PLACEHOLDER_REGISTRY.md`) will list all authorized placeholder data.
2. **Code Annotations**: Use the `// PLACEHOLDER DATA: Issue #123` annotation for easy searching.
3. **Automated Scanning**: Regular automated scans will identify unauthorized placeholder data.

## Removal Process

1. **Regular Review**: Placeholder data will be reviewed in each sprint planning.
2. **Prioritization**: Removal of placeholder data should be prioritized based on:
   - User impact
   - Technical debt
   - Ease of replacement
3. **Verification**: After removal, tests must verify that the system works correctly with real data.

## Enforcement

1. **Code Reviews**: All code reviews must check for compliance with this policy.
2. **CI/CD Checks**: Automated checks will flag unauthorized placeholder data.
3. **Technical Debt Tracking**: Placeholder data will be tracked as technical debt.

## Appendix: Placeholder Registry Template

The `PLACEHOLDER_REGISTRY.md` file should follow this template:

```markdown
# Placeholder Data Registry

| ID | Location | Purpose | Issue | Target Removal Date | Owner | Status |
|----|----------|---------|-------|---------------------|-------|--------|
| 1  | `lib/src/services/zim_catalog_service.dart` | Fallback ZIM catalog items | #123 | 2025-06-01 | @username | Active |
```
