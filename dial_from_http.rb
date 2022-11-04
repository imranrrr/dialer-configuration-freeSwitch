#!/usr/bin/ruby
# frozen_string_literal: false

require 'fsr'
require 'json'
require 'securerandom'
require 'sinatra'
require 'sinatra/basic_auth'
require 'sinatra/reloader'

set :bind, '0.0.0.0'

FSR.load_all_commands
$sock = FSR::CommandSocket.new
helpers do
def dial(number)
  params = { 'gateway' => 'asterisk',
             'phone' => number,
             'caller_id_number' => '712065010',
             'caller_id_name' => 'Dialer',
             'timeout' => 10 }

  params.each do |k, v|
    singleton_class.send(:attr_accessor, k)
    send("#{k}=", v)
  end

  first = '/home/michael/apps/freeswitch-docker-dialer/sounds/0.wav'
  second = '/home/michael/apps/freeswitch-docker-dialer/sounds/1.wav'

  s = $sock.originate(timeout: timeout, caller_id_number: caller_id_number, caller_id_name: caller_id_name,
                  target: "sofia/gateway/#{gateway}/#{phone}",
                  endpoint: '9196 XML default').run
end
end
# call '712305393'

authorize do |user_name, pass_word|
  user_name == '6ox9ztkJ' && pass_word == 'fjk43PVE'
end

protect do
  get '/dial/:phone' do 
    if params[:phone]
      erb dial(params[:phone]).inspect
    else
      erb 'no arguments'
    end
  end
end