module Rcov
  module Formatters
    class HTMLProfiling < HTMLCoverage
      DEFAULT_OPTS = { :destdir => "profiling" }

      def initialize(opts = {})
        options = DEFAULT_OPTS.clone.update(opts)
        super(options)
        @max_cache = {}
        @median_cache = {}
      end

      def default_title
        "Bogo-profile information"
      end

      def default_color
        if @color
          "rgb(179,205,255)"
        else
          "rgb(255, 255, 255)"
        end
      end

      def output_color_table?
        false
      end

      def span_class(sourceinfo, marked, count)
        full_scale_range = @fsr # dB
        nz_count = sourceinfo.counts.select{ |x| x && x != 0 }
        nz_count << 1 # avoid div by 0
        max = @max_cache[sourceinfo] ||= nz_count.max
        median = @median_cache[sourceinfo] ||= 1.0 * nz_count.sort[nz_count.size/2]
        max ||= 2
        max = 2 if max == 1

        if marked == true
          count = 1 if !count || count == 0
          idx = 50 + 1.0 * (500/full_scale_range) * Math.log(count/median) / Math.log(10)
          idx = idx.to_i
          idx = 0 if idx < 0
          idx = 100 if idx > 100
          "run#{idx}"
        else
          nil
        end
      end
    end
  end
end