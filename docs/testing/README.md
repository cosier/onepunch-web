# Testing Documentation

This directory contains test coverage plans, testing strategies, and quality assurance documentation for the OnePunch application.

## Current Coverage

**Overall Coverage**: 18.31% (286/1562 lines)
**Target Coverage**: 90%+
**Last Updated**: 2025-09-30

## Testing Documents

| Document | Purpose | Status |
|----------|---------|--------|
| [Coverage Plan](coverage-plan.md) | Test implementation roadmap | 📋 Active |
| [Coverage Index](coverage-index.md) | Comprehensive test file index | 📋 Active |

## Quick Commands

```bash
# Run all tests with coverage report
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run tests matching pattern
bundle exec rspec --pattern "*user*"

# View coverage report
open coverage/index.html

# Run only failed tests
bundle exec rspec --only-failures
```

## Testing Stack

- **Framework**: RSpec 3.x
- **Coverage**: SimpleCov (90% threshold)
- **Factories**: FactoryBot
- **Matchers**: Shoulda Matchers
- **HTTP Mocking**: VCR (for external APIs)
- **System Tests**: Capybara

## Testing Strategy

### Unit Tests (Models)
- Test all validations
- Test all associations
- Test scopes and class methods
- Test instance methods
- Target: 100% coverage

### Controller Tests
- Test authentication/authorization
- Test successful responses
- Test error handling
- Test data scoping
- Target: 90% coverage

### Integration Tests
- Test complete user workflows
- Test API endpoints
- Test background jobs
- Target: 85% coverage

### System Tests
- Test critical user journeys
- Test JavaScript interactions
- Test multi-browser compatibility
- Target: Key flows covered

## Coverage Milestones

- [x] 10% coverage (achieved: 18.31% ✅)
- [ ] 25% coverage
- [ ] 50% coverage
- [ ] 75% coverage
- [ ] 90% coverage (target)

## Priority Areas

### Phase 1: Core Models (Current)
- ✅ User model (52 tests)
- ✅ Organization model (45 tests)
- ✅ Project model (29 tests)
- ✅ TimeEntry model (27 tests)
- 🔄 OrganizationSetting (21 tests, 10 failing)
- ⏳ Invoice model
- ⏳ InvoiceLineItem model

### Phase 2: Controllers
- ⏳ Sessions/Authentication
- ⏳ Projects CRUD
- ⏳ Time Entries
- ⏳ Dashboard
- ⏳ Settings

### Phase 3: Integrations
- ⏳ Asana API Service
- ⏳ Asana OAuth
- ⏳ Asana Sync Job
- ⏳ AI Summaries

### Phase 4: Polish
- ⏳ Mailers
- ⏳ Admin controllers
- ⏳ System tests
- ⏳ Edge cases

## Best Practices

### Test Structure
```ruby
RSpec.describe Model do
  describe 'associations' do
    # Test relationships
  end

  describe 'validations' do
    # Test validation rules
  end

  describe 'scopes' do
    # Test query scopes
  end

  describe '#method_name' do
    # Test instance methods
  end

  describe '.class_method' do
    # Test class methods
  end
end
```

### Factory Usage
- Use `build` instead of `create` when DB persistence not needed
- Keep factories simple and composable
- Use traits for common variations
- Avoid creating unnecessary associations

### Test Organization
- Group related tests with `describe` and `context`
- Use descriptive test names that explain behavior
- Follow AAA pattern: Arrange, Act, Assert
- One assertion per test (when possible)

### Coverage Goals
- Don't chase 100% coverage blindly
- Focus on meaningful tests, not just lines covered
- Test behavior, not implementation details
- Write tests that provide value and confidence

## Continuous Integration

Tests run automatically on:
- Every pull request
- Every push to `develop` branch
- Before deployment to production

CI Requirements:
- All tests must pass
- Coverage must meet 90% threshold
- No security vulnerabilities (Brakeman)
- No linting errors (RuboCop)

## Resources

- [RSpec Documentation](https://rspec.info/)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers)
- [SimpleCov](https://github.com/simplecov-ruby/simplecov)
- [Coverage Plan](coverage-plan.md)
- [Coverage Index](coverage-index.md)
