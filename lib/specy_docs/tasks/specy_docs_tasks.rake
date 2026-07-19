# frozen_string_literal: true

namespace :specy_docs do
  desc 'Build SpecyDocs report JSON from captured request specs'
  task report: :environment do
    output_file = SpecyDocs.configuration.resolved_report_path
    SpecyDocs::ReportGenerator.call
    puts "Wrote SpecyDocs report to #{output_file}"
  end
end
