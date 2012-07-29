# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mothership/version"

Gem::Specification.new do |s|
  s.name        = "mothership"
  s.version     = Mothership::VERSION
  s.authors     = ["Alex Suraci"]
  s.email       = ["suraci.alex@gmail.com"]
  s.homepage    = "https://github.com/vito/mothership"
  s.summary     = %q{
    Command-line library for big honkin' CLI apps.
  }

  s.rubyforge_project = "mothership"

  s.files         = %w{LICENSE Rakefile} + Dir.glob("lib/**/*")
  s.test_files    = Dir.glob("spec/**/*")
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.3"
end
