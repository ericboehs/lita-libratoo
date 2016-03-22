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
          return reply_or_whisper_long response, response_text
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

        reply_or_whisper_long response, response_text
      rescue Exception => e
        reply_or_whisper_long response, e.message
      end

      route(/^librato sum\s(.+)/, :librato_sum, command: true, help: {
        "librato sum [metric] [options]" =>
          "example: 'lita librato sum payments_controller.stripe.success start_time: 2016-03-11-02:00'"
      })

      def librato_sum(response)
        Librato::Metrics.authenticate config.email, config.api_key

        arguments = response.matches[0][0].delete(':').split

        metric, options = arguments[0].to_sym, arguments[1..-1]
        options = symbolize_keys Hash[*options]
        options = { resolution: 1 }.merge options
        if options.key?(:start_time) && !options[:start_time].is_a?(Numeric)
          options[:start_time] = DateTime.parse(options[:start_time]).to_time.to_i
        end

        results = Librato::Metrics.get_composite %Q[sum(s("#{metric}", "*", {function: "sum"}))], options

        if results["measurements"].any?
          response_text = results["measurements"][0]["series"].reduce(0){|c,e| c + e["value"] }
        else
          response_text = "No results"
        end

        reply_or_whisper_long response, response_text
      rescue Exception => e
        reply_or_whisper_long response, e.message
      end

      route(/^librato search\s(.+)/, :librato_search, command: true, help: {
        "librato search [metric]" => "example: 'lita librato search replica'"
      })

      def librato_search(response)
        Librato::Metrics.authenticate config.email, config.api_key

        search = response.matches[0][0]

        metrics = Librato::Metrics.metrics.map{|v| v["name"] }
        response_text = metrics.grep(/#{search}/i).join(', ')
        response_text = "No results" if response_text.empty?
        reply_or_whisper_long response, response_text
      rescue Exception => e
        reply_or_whisper_long response, e.message
      end

      def symbolize_keys(hash)
        Hash[hash.map { |(k, v)| [ k.to_sym, v ] }]
      end

      Lita.register_handler(self)

      private

      def reply_or_whisper_long(response, response_text)
        response_text = response_text.to_s
        if response_text.length > 400 && !response.message.source.private_message
          response.reply "Large result set. Sending you a direct message."
          response.reply_privately response_text
        else
          response.reply response_text
        end
      end
    end
  end
end
