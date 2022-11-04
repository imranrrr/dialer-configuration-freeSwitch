#!/usr/bin/ruby
# frozen_string_literal: false

require 'sinatra'
require 'sinatra/basic_auth'
require 'sinatra/reloader'
require 'fsr'
require 'json'
require 'securerandom'
require 'active_record'
require 'yaml'

DEBUG = true

set :bind, '0.0.0.0'
FSR.load_all_commands
$sock = FSR::CommandSocket.new

helpers do
  def dial(number)
    param = { 'gateway' => 'asterisk',
              'phone' => number,
              'caller_id_number' => '712065010',
              'caller_id_name' => 'Dialer',
              'timeout' => 60 }

    param.each do |k, v|
      singleton_class.send(:attr_accessor, k)
      send("#{k}=", v)
    end

    s = $sock.originate(timeout: timeout, caller_id_number: caller_id_number, caller_id_name: caller_id_name,
                        target: "sofia/gateway/#{gateway}/#{phone.delete_prefix!('998')}",
                        endpoint: '9198 XML default').run
  end
end

authorize do |user_name, pass_word|
  user_name == '6ox9ztkJ' && pass_word == 'fjk43PVE'
end

protect do
  not_found do
    halt 404, 'not found'
  end

  get '/' do
    erb :index
  end

  get '/run' do
    erb :run
  end

  get '/dial' do
    erb :dial
  end

  post '/dial' do
    p 'PARAMS:', params.inspect
    if params[:phone] != ''
      d = dial params[:phone]
      erb 'Done! <a href="/">Return</a><br>'
    else
      erb 'Error! Fill phone field <a href="/dial">Return</a>'
    end
  end

  post '/run' do
    if params[:sequence] != ''
      sequence = params[:sequence]
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

      def call_to(number, sequence)
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
                        target: "{accountcode=#{sequence}}sofia/gateway/#{gateway}/#{phone}",
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
        pp call_to phone.delete_prefix!('998'), sequence
      end
      erb 'Done! <a href="/">Return</a><br>'
    else
      erb 'Error! Fill sequence field <br ><a href="/run">Return</a>'
    end
  end
end
