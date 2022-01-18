module DNS
  module Refinements
    module Transaction
      refine ::Async::DNS::Transaction do
        def passthrough(resolvers, options = {})
          Console.logger.debug "#" * 10
          query_name = options[:name] || name
          query_resource_class = options[:resource_class] || resource_class

          return resolvers.query(query_name, query_resource_class) unless resolvers.is_a?(Array)

          # responses = []
          #
          # Sync do
          #   manager = Async::Semaphore(2, parent: Async::Task.current)
          #
          #   resolvers.each do |resolver|
          #     manager.async do
          #       Console.logger.debug query_name
          #       Console.logger.debug resolver.inspect
          #       response = resolver.query(query_name, query_resource_class)
          #       Console.logger.debug "#" * 10
          #       Console.logger.debug response
          #       Console.logger.debug "#" * 10
          #
          #       responses << response if response
          #     end
          #   end
          # end
          #
          # Console.logger.debug "*" * 10
          # Console.logger.debug responses.inspect
          # Console.logger.debug "*" * 10
          # responses.first
        end
      end
    end
  end
end
