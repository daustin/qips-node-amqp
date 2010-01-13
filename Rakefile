require File.dirname(__FILE__) + '/config/boot'

require 'rake'
require 'daemon_kit/tasks'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "qips-node-amqp"
    gemspec.summary = "AMQP worker node for QIPS suite"
    gemspec.description = "Listens for jobs on a rabbit server, works closely with qipr-rmgr"
    gemspec.email = "daustin@mail.med.upenn.edu"
    gemspec.homepage = "http://github.com/daustin/qips-node-amqp"
    gemspec.authors = ["David Austin" ,"Andrew Brader"]
    Jeweler::GemcutterTasks.new
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end


Dir[File.join(File.dirname(__FILE__), 'tasks/*.rake')].each { |rake| load rake }
