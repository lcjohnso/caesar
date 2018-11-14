module Filters
  class Filter
    def initialize(config)
      @config = config.with_indifferent_access
    end

    def filter(_)
      raise NotImplementedError.new
    end
  end
end