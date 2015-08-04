module Listen
  module Adapter
    # Adapter implementation for Windows `jruby-notify`.
    #
    class Windows < Base
      OS_REGEXP = /mswin|mingw|cygwin/i

      BUNDLER_DECLARE_GEM = <<-EOS.gsub(/^ {6}/, '')
        Please add the following to your Gemfile to avoid polling for changes:
          gem 'jruby-notify' if Gem.win_platform?
      EOS

      def self.usable?
        return false unless super
        require 'jruby-notify'
        true
      rescue LoadError
        _log :debug, format('jruby-notify - load failed: %s:%s', $ERROR_INFO,
                            $ERROR_POSITION * "\n")

        Kernel.warn BUNDLER_DECLARE_GEM
        false
      end

      private

      def _configure(dir, &callback)
        require 'jruby-notify'
        _log :debug, 'jruby-notify - starting...'
        @workers = [] unless @workers
        notifier = JRubyNotify::Notify.new
        notifier.watch(dir.to_s, JRubyNotify::FILE_ANY, false, &callback)
        @workers.push({notifier: notifier, directory: dir})
      end

      def _run
        new_options = @config.adapter_options
        new_options[:recursive] = false
        @workers.each do |worker|
          _queue_change(:dir, worker[:directory], '.', new_options)
          worker[:notifier].run
        end
      end

      def _process_event(dir, *file_path)
        full_path = Pathname(::File.join(file_path))
        rel_path = full_path.relative_path_from(dir).to_s
        new_options = @config.adapter_options
        new_options[:recursive] = false
        _queue_change(:file, dir, rel_path, new_options)
      end

    end
  end
end

