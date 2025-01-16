require "socket"

module Sharry
  class Device
    def self.own_ip
      Socket.ip_address_list.detect(&:ipv4_private?).ip_address
    end

    def self.host_request?(request)
      request.ip == "127.0.0.1" || request.ip == own_ip
    end

    def self.get_device_name(ip)
      begin
        Socket.gethostbyaddr(ip.split(".").map(&:to_i).pack("C*")).first
      rescue SocketError
        nil
      end
    end
  end
end
