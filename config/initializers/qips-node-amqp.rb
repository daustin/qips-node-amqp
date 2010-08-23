begin
  require 'json'
rescue LoadError
  $stderr.puts "Missing json gem. Please run 'gem install json'"
  exit 1
end

begin
  require 'ruote'
rescue LoadError
  $stderr.puts "Missing ruote gem. Please run 'gem install ruote'"
  exit 1
end

begin
  require 'amqp'
  require 'mq'
rescue LoadError
  $stderr.puts "Missing amqp gem. Please run 'gem install amqp' if you wish to use the AMQP participant/listener pair in ruote"
end

begin
  require 'activeresource'
  require 'activesupport'
rescue LoadError
  $stderr.puts "Missing activeresource gem. Please run 'gem install activeresource' "
end

begin
  require 'rest_client'
rescue LoadError
  $stderr.puts "Missing rest-client gem. Please run 'gem install rest-client'"
end

begin
  require 'right_aws'
rescue LoadError
  $stderr.puts "Missing right_aws gem. Please run 'gem install right_aws'"
end
