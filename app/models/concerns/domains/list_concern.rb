module HostsRefinements
  require 'resolv'

  refine String do
    def host
      gsub(/^\d+\.\d+\.\d+\.\d+\s+|^[a-f0-9:]+(%\w+)?\s+|\s*#.*$|\d+\.\d+\.\d+\.\d+\s*$|[a-f0-9:]+\s*$/, '')
    end

    def comment?
      start_with?('#')
    end

    def dotless?
      exclude?('.')
    end

    def ip_address?
      !!(self =~ Regexp.union(Resolv::IPv4::Regex, Resolv::IPv6::Regex))
    end
  end
end

module Domains::ListConcern
  extend ActiveSupport::Concern

  using HostsRefinements

  def values
    response = Faraday.get(value)

    if response.success?
      response.body
              .gsub(/\s*#.*$|^\s+|^\s*\d+\.\d+\.\d+\.\d+\s+|^\s*[a-f0-9:]+(%\w+)?\s+|\d+\.\d+\.\d+\.\d+\s+|[a-f0-9:]+\s+/, '')
              .gsub(/^[^.]+\s+/, '')
              .gsub("\r", "\n")
              .gsub(/^\s+/, '')
              .split("\n")
              .uniq
      # response.body.each_line.lazy
      #         .reject(&:blank?)
      #         .map(&:strip).reject(&:comment?)
      #         .map(&:host).reject(&:dotless?).reject(&:ip_address?)
    else
      []
    end
  end
end

