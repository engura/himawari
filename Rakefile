# frozen-string-literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'spec'
  t.libs << 'lib'
  t.test_files = FileList['spec/**/test_*.rb']
end

desc 'Run tests'
task default: :test
