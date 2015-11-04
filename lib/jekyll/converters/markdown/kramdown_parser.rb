# Frozen-string-literal: true
# Encoding: utf-8

module Jekyll
  module Converters
    class Markdown
      class KramdownParser
        CODERAY_DEFAULTS = {
          "bold_every" => 10,
          "css" => "style",
          "line_numbers" => "inline",
          "line_number_start" => 1,
          "wrap" => "div",
          "tab_width" => 4
        }

        def initialize(config)
          Jekyll::External.require_with_graceful_fail "kramdown"
          @main_fallback_highlighter = config["highlighter"] || "rogue"
          @config = config["kramdown"] || {}
          setup
        end

        # Setup and normalize the configuration:
        #   * Create Kramdown if it doesn't exist.
        #   * Set syntax_highlighter, detecting enable_coderay and merging highlighter if none.
        #   * Merge kramdown[coderay] into syntax_highlighter_opts stripping coderay_.
        #   * Make sure `syntax_highlighter_opts` exists.

        def setup
          @config["syntax_highlighter"] ||= highlighter
          @config["syntax_highlighter_opts"] ||= {}
          @config["coderay"] ||= {} # XXX: Legacy.
          modernize_coderay_config
        end

        def convert(content)
          Kramdown::Document.new(content, @config).to_html
        end

        # config[kramdown][syntax_higlighter] > config[kramdown][enable_coderay] > config[highlighter]
        # Where `enable_coderay` is now deprecated because Kramdown
        # supports Rouge now too.

        private
        def highlighter
          @highlighter ||= begin
            if out = @config["syntax_highlighter"] then out
            elsif @config.has_key?("enable_coderay") && @config["enable_coderay"]
              Jekyll.logger.warn "You are using enable_coderay, use syntax_highlighter: coderay." \
                "In the future enable_coderay will be removed entirely."
              "coderay"
            else
              @main_fallback_highlighter
            end
          end
        end

        private
        def strip_coderay_prefix(hash)
          hash.inject({}) do |hash_, (key, val)|
            cleaned_key = key.gsub(/\Acoderay_/, "")
            if hash.has_key?(key)
              Jekyll.logger.warn "You are using an old CodeRay key: '#{key}'." \
                "It is being normalized to #{cleaned_key}."
            end

            hash_.update({
              cleaned_key => val
            })
          end
        end

        private
        def modernize_coderay_config
          if highlighter == "coderay"
            @config["syntax_highlighter_opts"] = strip_coderay_prefix(
              @config["syntax_highlighter_opts"].merge(CODERAY_DEFAULTS).merge(@config["coderay"])
            )
          end
        end
      end
    end
  end
end
