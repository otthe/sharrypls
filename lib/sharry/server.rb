require 'sinatra/base'
require 'socket'
require_relative 'config'

module Sharry
  class Server < Sinatra::Base
    @host = Sharry::Config.get(:host)
    @port = Sharry::Config.get(:port)

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

  end
end