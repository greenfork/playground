# frozen_string_literal: true
require "roda"
require_relative "db"

class App < Roda
  plugin :symbol_views
  plugin :render, escape: true, assume_fixed_locals: true,
    template_opts: {
      scope_class: self,
      freeze: true,
      extract_fixed_locals: true,
      default_fixed_locals: "()",
      chain_appends: true,
      skip_compiled_encoding_detection: true,
    }
  plugin :assets, css: "styles.css", js: "app.js"
  plugin :public
  plugin :part
  plugin :head

  route do |r|
    r.public
    r.assets

    r.root do
      @report = RUNNER << :report
      :report
    end

    r.get "logs" do
      response.headers["content-type"] = "text/event-stream"
      response.headers["cache-control"] = "no-cache"

      logs_port = Queue.new
      RUNNER.log_subscribe logs_port

      body = proc do |stream|
        until stream.closed?
          if log = logs_port.pop(timeout: 3)
            stream << <<~SSE
              data: #{log}

            SSE
          else
            stream << ":\n\n"
          end
        end
      rescue => error
      ensure
        stream.close(error)
        RUNNER.log_unsubscribe logs_port
        logs_port.close
      end

      throw :halt, @_response.finish_with_body(body)
    end

    r.on "programs" do
      r.post "start_all" do
        RUNNER << :start_all
        r.redirect "/"
      end

      r.post "stop_all" do
        RUNNER << :stop_all
        r.redirect "/"
      end

      r.on String do |program_id|
        r.post "start" do
          RUNNER << [:start, program_id]
          r.redirect "/"
        end

        r.post "stop" do
          RUNNER << [:stop, program_id]
          r.redirect "/"
        end

        r.post "restart" do
          RUNNER << [:restart, program_id]
          r.redirect "/"
        end
      end
    end
  end
end
