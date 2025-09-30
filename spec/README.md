# OnePunch Test Suite

This directory contains the RSpec test suite for OnePunch with code coverage tracking via SimpleCov.

## Quick Start

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run tests with documentation format
bundle exec rspec --format documentation

# Run tests matching a pattern
bundle exec rspec spec/models/

# View coverage report (after running tests)
open coverage/index.html
```

## Test Organization

```
spec/
├── factories/          # FactoryBot test data factories
├── fixtures/           # Static test data (VCR cassettes, etc.)
├── models/             # Model unit tests
├── controllers/        # Controller/request tests
├── services/           # Service object tests
├── jobs/               # Background job tests
├── mailers/            # Mailer tests
├── support/            # Shared test helpers and configuration
│   ├── factory_bot.rb  # FactoryBot configuration
│   └── vcr.rb          # VCR configuration for HTTP mocking
├── rails_helper.rb     # Rails-specific test configuration
└── spec_helper.rb      # General RSpec configuration + SimpleCov
```

## Code Coverage

### Current Status
- **Coverage:** 9.67% (baseline)
- **Target:** 90%+ overall, 80%+ per file
- **Coverage Reports:** `coverage/index.html`

### Coverage Configuration

SimpleCov is configured in `spec/spec_helper.rb` with:
- Filters for `/bin/`, `/db/`, `/spec/`, `/config/`, `/vendor/`
- Groups by file type (Controllers, Models, Services, etc.)
- HTML and console output formats
- Minimum coverage thresholds (gradually increasing)

### Viewing Coverage

After running tests, open the HTML report:
```bash
open coverage/index.html  # macOS
xdg-open coverage/index.html  # Linux
```

Or view in terminal with:
```bash
bundle exec rspec --format documentation
```

## Testing Tools

### FactoryBot
Used for creating test data. Factories defined in `spec/factories/`.

```ruby
# Create a user
user = create(:user)

# Create with traits
user = create(:user, :admin)

# Build without saving
user = build(:user)

# Create with associations
project = create(:project, organization: org)
```

### VCR
Records and replays HTTP interactions for external API tests.

```ruby
RSpec.describe AsanaApiService, :vcr do
  it 'fetches workspaces' do
    # HTTP requests are recorded to spec/fixtures/vcr_cassettes/
    service.fetch_workspaces
  end
end
```

### WebMock
Stubs HTTP requests when not using VCR.

```ruby
allow(HTTParty).to receive(:get).and_return(
  double(code: 200, body: '{"data": []}')
)
```

## Test Examples

### Model Test
```ruby
RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:organizations).through(:memberships) }
    it { should belong_to(:current_organization).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
  end

  describe '#role_in' do
    it 'returns the user role for an organization' do
      user = create(:user)
      org = create(:organization)
      create(:membership, user: user, organization: org, role: :owner)

      expect(user.role_in(org)).to eq('owner')
    end
  end
end
```

### Controller/Request Test
```ruby
RSpec.describe ProjectsController, type: :request do
  let(:user) { create(:user, :with_current_organization) }
  let(:organization) { user.current_organization }

  before { sign_in user }

  describe 'GET #index' do
    it 'returns successful response' do
      get projects_path
      expect(response).to be_successful
    end

    it 'displays user projects' do
      project = create(:project, organization: organization)
      get projects_path
      expect(response.body).to include(project.name)
    end
  end

  describe 'POST #create' do
    it 'creates a new project' do
      expect {
        post projects_path, params: { project: { name: 'Test Project' } }
      }.to change(Project, :count).by(1)
    end
  end
end
```

### Service Test
```ruby
RSpec.describe AsanaApiService do
  let(:credential) { create(:asana_credential) }
  let(:service) { described_class.new(credential) }

  describe '#fetch_workspaces' do
    it 'returns workspaces from API' do
      # Stub HTTP request
      allow(HTTParty).to receive(:get).and_return(
        double(code: 200, body: '{"data": [{"gid": "123", "name": "Test"}]}')
      )

      workspaces = service.fetch_workspaces
      expect(workspaces).to be_an(Array)
      expect(workspaces.first['gid']).to eq('123')
    end
  end
end
```

## Test Data

### Factories
All test models have corresponding factories in `spec/factories/`:
- Users (with traits: `:admin`, `:with_google_oauth`, `:with_current_organization`)
- Organizations (with traits: `:personal`, `:business`)
- Projects (with traits: `:active`, `:archived`, `:billable`)
- TimeEntries (with traits: `:running`, `:stopped`, `:today`)
- And more...

### Using Traits
```ruby
# Create admin user
admin = create(:user, :admin)

# Create personal organization
org = create(:organization, :personal)

# Create running timer
timer = create(:time_entry, :running, user: user, project: project)
```

## CI/CD Integration

### GitHub Actions (example)
```yaml
- name: Run tests
  run: bundle exec rspec

- name: Upload coverage
  uses: actions/upload-artifact@v3
  with:
    name: coverage-report
    path: coverage/
```

## Development Workflow

1. **Write test first** (TDD approach)
2. **Run test** to see it fail
3. **Implement feature**
4. **Run test** to see it pass
5. **Refactor** if needed
6. **Check coverage** to ensure adequate testing

## Resources

- [RSpec Documentation](https://rspec.info/)
- [FactoryBot](https://github.com/thoughtbot/factory_bot)
- [SimpleCov](https://github.com/simplecov-ruby/simplecov)
- [VCR](https://github.com/vcr/vcr)
- [WebMock](https://github.com/bblimke/webmock)

## Coverage Goals

See `docs/test_coverage_plan.md` for detailed coverage improvement plan.