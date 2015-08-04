module Listen
  module Adapter
    # Polling Adapter that works cross-platform and
    # has no dependencies. This is the adapter that
    # uses the most CPU processing power and has higher
    # file IO than the other implementations.
    #
    class Polling < Base
      OS_REGEXP = // # match every OS

      DEFAULTS = { latency: 1.0, wait_for_delay: 0.05, check_with_size: false }

      private

      def _configure(_, &callback)
        @polling_callbacks ||= []
        @polling_callbacks << callback
      end

      def _run
        loop do
          @polling_callbacks.each do |callback|
            callback.call(nil)
            # TODO: warn if nap_time is negative (polling too slow)
            sleep(options.latency) if options.latency > 0
          end
        end
      end

      def _process_event(dir, _)
        new_options = @config.adapter_options
        new_options[:recursive] = false
        _queue_change(:dir, dir, '.', new_options)
      end
    end
  end
end
