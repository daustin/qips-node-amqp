begin
  require 'json'
rescue LoadError
  $stderr.puts "Missing json gem. Please run 'gem install json'"
  exit 1
end

begin
  require 'amqp'
  require 'mq'
rescue LoadError
  $stderr.puts "Missing amqp gem. Please run 'gem install amqp' if you wish to use the AMQP participant/listener pair in ruote"
end

begin
  require 'activerecord'
  require 'activesupport'
rescue LoadError
  $stderr.puts "Missing activerecord gem. Please run 'gem install activerecord' "
end

begin
  require 'httpclient'
rescue LoadError
  $stderr.puts "Missing httpclient gem. Please run 'gem install httpclient'"
end
