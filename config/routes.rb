# frozen_string_literal: true

SpecyDocs::Engine.routes.draw do
  root to: 'docs#show'
  get 'report.json', to: 'docs#report', as: :report
  get 'app.js', to: 'docs#javascript', as: :app_js
  get 'styles.css', to: 'docs#stylesheet', as: :app_css
end
