require "rubygems"
require "bundler"

if Gem::Version.new(Bundler::VERSION) > Gem::Version.new("1.0.12")
  require "bundler/gem_tasks"
end

task :default => "spec"

desc "Run specs"
task "spec" => ["bundler:install", "test:spec"]

namespace "bundler" do
  desc "Install gems"
  task "install" do
    sh("bundle install")
  end
end

namespace "test" do
  task "spec" do |t|
    sh("cd spec && bundle exec rake spec")
  end
end
