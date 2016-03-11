require "librato/metrics"
module Lita
  module Handlers
    class Libratoo < Handler
      config :email, required: true
      config :api_key, required: true

      route(/^librato get\s(.+)/, :librato_get, command: true, help: {
        "librato get [metric] [options]" =>
          "example: 'lita librato get AWS.RDS.ReplicaLag source: * count: 5 start_time: 2016-03-11-02:00'"
      })

      def librato_get(response)
        Librato::Metrics.authenticate config.email, config.api_key

        arguments = response.matches[0][0].delete(':').split

        if arguments[0] == "search"
          metrics = Librato::Metrics.metrics.map{|v| v["name"] }
          response_text = metrics.grep(/#{arguments[1]}/i).join(', ')
          response_text = "No results" if response_text.empty?
          if response_text.length > 400 && !response.message.source.private_message
            return response.reply "Large result set. Sending you a direct message."
            return response.reply_privately response_text
          else
            return response.reply response_text
          end
        end

        metric, options = arguments[0].to_sym, arguments[1..-1]
        options = symbolize_keys Hash[*options]
        options = { count: 1 }.merge options
        if options.key?(:start_time) && !options[:start_time].is_a?(Numeric)
          options[:start_time] = DateTime.parse(options[:start_time]).to_time
        end

        results = Librato::Metrics.get_measurements metric, options
        results = Hash[results.map {|source, r| [source, r.map{|v| v["value"] }]}]

        if results.keys.count == 0
          response_text = "No results"
        elsif results.keys.count == 1
          response_text = results.values.flatten.join ', '
        else
          response_text = results.map{|k,v| "#{k}: #{v.join ', '}" }.join "\n"
        end

        if response_text.length > 400 && !response.message.source.private_message
          return response.reply "Large result set. Sending you a direct message."
          return response.reply_privately response_text
        else
          return response.reply response_text
        end
      end

      route(/^librato search\s(.+)/, :librato_search, command: true, help: {
        "librato search [metric]" => "example: 'lita librato search replica'"
      })

      def librato_search(response)
        Librato::Metrics.authenticate config.email, config.api_key

        arguments = response.matches[0][0].delete(':').split

        metrics = Librato::Metrics.metrics.map{|v| v["name"] }
        response_text = metrics.grep(/#{arguments[1]}/i).join(', ')
        response_text = "No results" if response_text.empty?
        if response_text.length > 400 && !response.message.source.private_message
          return response.reply "Large result set. Sending you a direct message."
          return response.reply_privately response_text
        else
          return response.reply response_text
        end
      end

      def symbolize_keys(hash)
        Hash[hash.map { |(k, v)| [ k.to_sym, v ] }]
      end

      Lita.register_handler(self)
    end
  end
end
