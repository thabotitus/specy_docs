# SpecyDocs

Capture RSpec request examples and serve a mountable docs UI.
  - Use it if you want readable low-config docs for your team.
  - Use it to uncover endpoints that you may not know exist. 
  - Use it if swagger and the hoops you have to jump are annoying, when you just want to show teams how to use your API with your tested code.

## Installation

```ruby
# Gemfile
gem 'specy_docs'
```

```bash
bundle install
```

## Mount the engine

```ruby
# config/routes.rb
mount SpecyDocs::Engine => '/docs'
```

Any path works, e.g. `/api-docs` or `/internal/specy`.

## Capture request specs

Prefer the setup helper so include filters follow your configuration:

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  SpecyDocs.setup_rspec(config)
end
```

Or include manually:

```ruby
config.include SpecyDocs::Capturable, type: :request
```

### Capture folders (legacy controller specs without `type:`)

If controller (or other) specs are not tagged with `type: :request`, and adding a type breaks them, set folders to capture from instead. SpecyDocs will include `Capturable` by file path for those folders. `opt_in` / `specy` tags still apply.

```ruby
# config/initializers/specy_docs.rb
SpecyDocs.configure do |config|
  config.capture_paths = %w[spec/controllers spec/requests]
  config.opt_in = true
end
```

```ruby
# spec/rails_helper.rb — must use setup_rspec (or include by file_path yourself)
RSpec.configure do |config|
  SpecyDocs.setup_rspec(config)
end
```

Only examples under those folders are candidates; then:

- `opt_in: true` → capture when `specy: true`
- `opt_in: false` → capture all in those folders except `specy: false`

### Opt-in mode (default: `opt_in: true`)

Only examples (or groups) tagged with `specy: true` are captured:

```ruby
RSpec.describe 'Certificates', type: :request do
  it 'returns the certificate', specy: true do
    get '/certificates/example.com'
    expect(response).to have_http_status(:ok)
  end

  # Not captured
  it 'returns not found' do
    get '/certificates/missing.com'
    expect(response).to have_http_status(:not_found)
  end
end
```

### Opt-out mode (`opt_in: false`)

All matching request specs are captured unless tagged with `specy: false`:

```ruby
# config/initializers/specy_docs.rb
SpecyDocs.configure do |config|
  config.opt_in = false
end

RSpec.describe 'Status', type: :request do
  it 'returns success status' do
    get '/status' # captured
  end

  it 'skips noise', specy: false do
    get '/status' # not captured
  end
end
```

## Generate the report

```bash
bin/rails specy_docs:report
```

Then open the mounted path (e.g. `http://localhost:3000/docs`).

## Optional configuration

```ruby
# config/initializers/specy_docs.rb
SpecyDocs.configure do |config|
  config.title = 'CDN API'
  config.eyebrow = 'cdn-api'
  config.opt_in = true # default; set false to capture all except `specy: false`
  config.capture_paths = %w[spec/controllers spec/requests] # optional; empty = type: :request only
  config.capture_path = Rails.root.join('tmp/specy_docs/captures.json')
  config.report_path = Rails.root.join('tmp/specy_docs/report.json')
  config.masked_header_keys = %w[
    Authorization
  ]
end
```

## Notes for API-only apps

SpecyDocs loads Action Controller and Action View railties inside the engine, so the UI renders even when the host app uses `config.api_only = true`.

## Releasing

Releases are prepared locally and published by GitHub Actions when you publish the draft GitHub release.

### One-time setup

1. Create a RubyGems API key with **Push rubygem** permission.
2. Add it as a repository secret named `RUBYGEMS_API_KEY`.
3. Ensure a long-lived `release` branch exists (or let `bin/release` create it on first run).

### Cut a release

```bash
bin/release
```

You will be prompted for bump type (patch / minor / major). Release notes are
generated from commits via the GitHub API (same source as GitHub auto notes),
previewed for confirmation, then written into `CHANGELOG.md` and the draft release.

The script will:

1. Fetch remotes and tags
2. Check out `release` and merge `origin/main`
3. Generate release notes from commits since the previous tag
4. Bump `lib/specy_docs/version.rb` and prepend those notes to `CHANGELOG.md`
5. Commit, tag (`vX.Y.Z`), and push `release` + the tag
6. Create a **draft** GitHub release with the same notes

Then open the draft on GitHub, review the notes, and click **Publish release**. That triggers `.github/workflows/publish-gem.yml`, which builds the gem and runs `gem push`.

Preview without changing anything:

```bash
bin/release --dry-run
```

Requires a clean working tree, `gh` authenticated to the repo, and push access to `origin`.