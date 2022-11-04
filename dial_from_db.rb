#!/usr/bin/ruby
# frozen_string_literal: false

require 'fsr'
require 'json'
require 'securerandom'
require 'active_record'
require 'yaml'

if ARGV[0]
  dial = ARGV[0]
else
  puts 'No dial arguments found'
  exit
end  

settings = YAML.load_file("#{__dir__}/config.yml")
run = settings['development']
pp run

ActiveRecord::Base.logger = ActiveSupport::Logger.new($stdout)

begin
  ActiveRecord::Base.establish_connection(
    adapter: 'mysql2',
    host: run['mysql_host'],
    username: run['mysql_user'],
    password: run['mysql_password'],
    database: run['mysql_db'],
    socket: run['socket']
  )
rescue StandardError => e
  pp e
end

FSR.load_all_commands
$sock = FSR::CommandSocket.new

def call(number, dial)
  params = { 'gateway' => 'asterisk',
             'phone' => number,
             'caller_id_number' => '712065010',
             'caller_id_name' => 'Dialer',
             'timeout' => 60 }

  params.each do |k, v|
    singleton_class.send(:attr_accessor, k)
    send("#{k}=", v)
  end

  $sock.originate(timeout: timeout, caller_id_number: caller_id_number, caller_id_name: caller_id_name,
                  target: '{accountcode=' + dial  + '}' + "sofia/gateway/#{gateway}/#{phone}",
                  endpoint: '9196 XML default').run
end

class User < ActiveRecord::Base
  scope :active, -> { where(active: true) }
end

phones = []

User.active.each do |user|
  phones << user.phone
  phones << user.phone1
  phones << user.phone2
end

pp phones

phones.compact.uniq.each do |phone|
  pp phone
  pp call phone.delete_prefix!('998'), dial
  # sleep 1
end
