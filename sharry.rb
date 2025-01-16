require 'sinatra'
require 'socket'

WHITELIST = ['127.0.0.1']
PENDING = []
set :bind, '0.0.0.0'
set :port, 8080

puts Socket.ip_address_list.detect(&:ipv4_private?).ip_address

def host_request?(request)
  request.ip == '127.0.0.1' || request.ip == Socket.ip_address_list.detect(&:ipv4_private?).ip_address
end

def get_device_name(ip)
  begin
    Socket.gethostbyaddr(ip.split('.').map(&:to_i).pack('C*')).first
  rescue SocketError
    nil
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
  halt 403, "Access forbidden: Admin only." unless host_request?(request)
  <<-HTML
    <h3>Admin Panel</h3>
    <hr>
    <p>Refresh the page to update pending requests</p>
    <h4>Pending Requests</h4>
    <hr>

    <ul>
      #{PENDING.map { |ip| "<li>[#{get_device_name(ip)}] | (#{ip}) | <a href='/admin/accept?ip=#{ip}'>Accept</a></li>" }.join}
    </ul>
    <h4>Whitelisted Devices</h4>
    <hr>
    <ul>
      #{WHITELIST.map { |ip| "<li>[#{get_device_name(ip)}] | (#{ip})</li>" }.join}
    </ul>
  HTML
end

get '/admin/accept' do
  halt 403, "Access forbidden: Admin only." unless host_request?(request)

  ip_to_accept = params['ip']
  if PENDING.include?(ip_to_accept)
    PENDING.delete(ip_to_accept)
    WHITELIST << ip_to_accept unless WHITELIST.include?(ip_to_accept)
    "IP #{ip_to_accept} has been whitelisted. <a href='/admin'>Back to Admin</a>"
  else
    "IP #{ip_to_accept} is not in the pending list. <a href='/admin'>Back to Admin</a>"
  end
end