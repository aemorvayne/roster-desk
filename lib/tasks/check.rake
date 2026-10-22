require 'rake/testtask'

task :prepare_coverage do
  FileUtils.rm_rf(%w[coverage .nyc_output tmp/instrumented])
  FileUtils.mkdir_p('.nyc_output')
  sh 'npm run instrument'
end

Rake::TestTask.new(:verify) do |task|
  task.libs << 'test'
  task.pattern = 'test/**/*_test.rb'
  task.warning = false
end

task verify: :prepare_coverage do
  sh 'npm run coverage'
end
