# SpecyDocs

Capture RSpec request examples and serve a mountable docs UI.

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
