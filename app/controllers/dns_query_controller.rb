require 'dns/server'

class DnsQueryController < ApplicationController
  skip_before_action :doorkeeper_authorize!
  before_action :check_content_type, only: :create

  IN = Resolv::DNS::Resource::IN

  def show
    dns_param = params[:dns] || ''

    if dns_param.size > 683
      render_plain "The requested URL /dns-query?dns=#{dns_param}... is too large to process. GET dns parameter more than 683 bytes long.", status: :uri_too_long

      return
    end

    response = resolv(dns_param)

    render_response(response)
  end

  def create
    dns_param = request.body.read || ''

    if dns_param.size > 512
      render_plain "Your client issued a request that was too large. DNS message more than 512 bytes long.", status: :payload_too_large

      return
    end

    response = resolv(dns_param)

    render_response(response)
  end

  def not_implemented
    render_plain "The server is unable to process your request. Unsupported method: '#{request.request_method}'. Only GET and POST are supported.", status: :not_implemented
  end

  private

  def check_content_type
    if request.headers['Content-Type'].blank?
      render_error 'No content-type header.'
    elsif request.headers['Content-Type'] != 'application/dns-message'
      render_plain "The media type is not supported. Unsupported content type: '#{request.headers['Content-Type']}'.", status: :unsupported_media_type
    end
  end

  def decode64(data)
    return data unless data&.match(/^[a-zA-Z0-9+\/=]+$/)

    if data.include?('=')
      render_error 'Base64Url dns parameter MUST NOT include trailing ‘=’ padding.'

      return
    end

    decoded = Base64.decode64(data)

    if data.present? && Base64.strict_encode64(decoded).delete_suffix('==').delete_suffix('=') != data
      render_error 'Base64Url parsing failed.'

      return
    elsif decoded.size < 12
      render_error 'DNS message less than 12 bytes long.'

      return
    end

    decoded
  end

  def decode_message(data)
    return unless data

    Async::DNS::decode_message(data)
  rescue Async::DNS::DecodeError
    render_error 'Invalid DNS message: parse failure and bad flags.'

    nil
  end

  def resolv(dns_param)
    data = decode64(dns_param)
    query = decode_message(data)

    return unless query

    start_time = Time.now
    remote_address = Addrinfo.tcp(request.remote_ip, request.port)
    server = OpenStruct.new(logger: request.logger)
    response = Resolv::DNS::Message::new(query.id)
    response.qr = 1
    response.opcode = query.opcode
    response.aa = 1
    response.rd = query.rd
    response.ra = 0
    response.rcode = 0

    begin
      query.question.each do |question, resource_class|
        start_question_time = Time.now

        request.logger.debug "<#{query.id}> Processing question #{question} #{resource_class.name}..."
        request.logger.debug "<#{query.id}> Searching for #{question} #{resource_class.name}"

        question = question.without_origin('.')
        transaction = Async::DNS::Transaction.new(server, query, question, resource_class, response, remote_address: remote_address)

        if [IN::A, IN::AAAA].include?(resource_class)
          if DNS::Server.blocked?(transaction, request.logger)
            request.logger.debug "<#{query.id}> Callable pattern matched."

            DNS::Server.blocked_logger(transaction, request.logger)

            case resource_class
            when IN::A
              transaction.respond!('127.0.0.1')
            when IN::AAAA
              transaction.respond!('::1')
            end
          else
            request.logger.debug "<#{query.id}> No pattern matched."
          end
        else
          request.logger.debug "<#{query.id}> Resource class #{resource_class.name} failed to match A!"
          request.logger.debug "<#{query.id}> Resource class #{resource_class.name} failed to match AAAA!"

          Sync do
            transaction.passthrough!(DNS::Server::UPSTREAM)
          end
        end

        end_question_time = Time.now
        DNS::Server.question_logger(transaction, end_question_time - start_question_time, request.logger)
      rescue Resolv::DNS::OriginError
        request.logger.debug "<#{query.id}> Skipping question #{question} #{resource_class} because #{$!}"
      end
    rescue StandardError => error
      response.rcode = Resolv::DNS::RCode::ServFail

      request.logger.error(error)
    end

    end_time = Time.now
    request.logger.debug "<#{query.id}> Time to process request: #{end_time - start_time}s"
    response
  end

  def render_response(message)
    return unless message

    encoded = message.encode

    response.headers['Content-Length'] = encoded.bytesize
    response.headers['Content-Type'] = 'application/dns-message'

    render_plain encoded
  end

  def render_error(message)
    request.logger.info message

    render_plain "Your client has issued a malformed or illegal request. #{message}", status: :bad_request
  end

  def render_plain(message, status: :ok)
    render plain: message, layout: nil, status: status
  end
end
