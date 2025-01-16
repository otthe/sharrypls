require 'sinatra/base'
require 'socket'
require_relative 'config'

module Sharry
  class Server < Sinatra::Base
    @host = Sharry::Config.get(:host)
    @port = Sharry::Config.get(:port)

    WHITELIST = ['127.0.0.1']
    PENDING = []

    set :bind, @host
    set :port, @port
    set :root, Dir.pwd

    # in the current implementation this method must be called outside of this class
    # before calling 'start!' -method for the server
    def self.kill_existing_server(host, port)
      begin
        server_socket = TCPSocket.new(host, port)
        server_socket.close
        puts "Server is already running on #{host}:#{port}. Killing it..."
        `lsof -i :#{port} | grep LISTEN | awk '{print $2}' | xargs kill -9`
      rescue Errno::ECONNREFUSED
        puts "no server running on port #{port}"
      end
    end

    # this method is used to add some delay before using launchy to open the app on browser
    # it should be called after starting a server on a new thread and before using launchy to launch
    def self.wait_for_server(host, port, timeout = 10)
      start_time = Time.now
      loop do
        begin
          TCPSocket.new(host, port).close
          puts "server is up and running on  #{host}:#{port}"
          break
        rescue Errno::ECONNREFUSED
          if Time.now - start_time > timeout
            puts "Server failed to start within #{timeout} seconds"
            exit(1)
          end
          sleep 0.1
        end
      end
    end

    get '/' do
      if WHITELIST.include?(request.ip)
        "Welcome! You have access to the index."
      else
        unless PENDING.include?(request.ip)
          PENDING << request.ip
        end
        halt 403, "Your IP (#{request.ip}) is not whitelisted. Waiting for admin approval."
      end
    end

    get '/admin' do
      halt 403, "Access forbidden: Admin only." unless Sharry::Device.host_request?(request)
      <<-HTML
        <h3>Admin Panel</h3>
        <hr>
        <p>Refresh the page to update pending requests</p>
        <h4>Pending Requests</h4>
        <hr>

        <ul>
          #{PENDING.map { |ip| "<li>[#{Sharry::Device.get_device_name(ip)}] | (#{ip}) | <a href='/admin/accept?ip=#{ip}'>Accept</a></li>" }.join}
        </ul>
        <h4>Whitelisted Devices</h4>
        <hr>
        <ul>
          #{WHITELIST.map { |ip| "<li>[#{Sharry::Device.get_device_name(ip)}] | (#{ip})</li>" }.join}
        </ul>
      HTML
    end

    get '/admin/accept' do
      halt 403, "Access forbidden: Admin only." unless Sharry::Device.host_request?(request)
    
      ip_to_accept = params['ip']
      if PENDING.include?(ip_to_accept)
        PENDING.delete(ip_to_accept)
        WHITELIST << ip_to_accept unless WHITELIST.include?(ip_to_accept)
        "IP #{ip_to_accept} has been whitelisted. <a href='/admin'>Back to Admin</a>"
      else
        "IP #{ip_to_accept} is not in the pending list. <a href='/admin'>Back to Admin</a>"
      end
    end

  end
end