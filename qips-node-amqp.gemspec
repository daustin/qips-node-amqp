# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{qips-node-amqp}
  s.version = "0.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Austin", "Andrew Brader"]
  s.date = %q{2010-01-28}
  s.description = %q{Listens for jobs on a rabbit server, works closely with qipr-rmgr}
  s.email = %q{daustin@mail.med.upenn.edu}
  s.executables = ["qips-node-amqp", "status-updater.rb"]
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    ".gitignore",
     "README",
     "Rakefile",
     "VERSION",
     "bin/qips-node-amqp",
     "bin/status-updater.rb",
     "config/amqp.yml",
     "config/arguments.rb",
     "config/boot.rb",
     "config/environment.rb",
     "config/environments/development.rb",
     "config/environments/production.rb",
     "config/environments/test.rb",
     "config/initializers/qips-node-amqp.rb",
     "config/post-daemonize/readme",
     "config/pre-daemonize/readme",
     "config/ruote.yml",
     "lib/qips-node-amqp.rb",
     "lib/resource_manager_interface.rb",
     "lib/s3_helper.rb",
     "lib/sample.rb",
     "lib/status_writer.rb",
     "lib/work_item_helper.rb",
     "lib/worker.rb",
     "libexec/qips-node-amqp-daemon.rb",
     "pills/qips-node.pill",
     "pkg/qips-node-amqp-0.1.0.gem",
     "qips-node-amqp.gemspec",
     "script/console",
     "script/destroy",
     "script/generate",
     "spec/qips-node-amqp_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "tasks/rspec.rake"
  ]
  s.homepage = %q{http://github.com/daustin/qips-node-amqp}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{AMQP worker node for QIPS suite}
  s.test_files = [
    "spec/qips-node-amqp_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

