# Pull Request

## Description
<!-- Brief description of changes -->

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Refactoring (no functional changes)

## State Management Checklist
<!-- Required for all PRs touching state management -->

- [ ] No business logic in `initState`, `didUpdateWidget`, or `dispose`
- [ ] State-dependent side effects use `ref.listen()` or event streams
- [ ] All async operations are properly awaited or explicitly unawaited
- [ ] Critical state changes have logging for debugging
- [ ] No duplicate sources of truth for the same state
- [ ] State transitions are explicit and documented

## Testing
<!-- Required for all functional changes -->

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated (for user-facing flows)
- [ ] Manual testing completed

### Test Coverage
- [ ] New code has >80% test coverage
- [ ] Critical paths have integration tests

## Repository Pattern
<!-- Required for data operations -->

- [ ] All Firestore/API calls go through repositories
- [ ] No direct `FirebaseFirestore.instance` calls in presentation layer
- [ ] Error handling implemented for all data operations

## How to Test
<!-- Steps for reviewers to verify changes -->

1.
2.
3.

## Screenshots/Logs
<!-- For UI changes or debugging -->

## Related Issues
<!-- Link to issues: Fixes #123 -->

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated (if needed)
- [ ] No new warnings introduced
- [ ] Tested on target platforms (web/mobile)

---

**Review ARCHITECTURE_GUIDELINES.md before approving PRs touching state management.**
