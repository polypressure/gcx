require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test

task :generate_data, [:num_listings, :filename] do |t, args|
  require_relative 'test/tools/dataset_generator'
  GCX::DatasetGenerator.generate_input_file(args[:num_listings], args[:filename])
end
