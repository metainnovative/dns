Faraday.default_connection = Faraday.new do |conn|
  conn.use FaradayMiddleware::FollowRedirects
  conn.adapter Faraday.default_adapter
end
