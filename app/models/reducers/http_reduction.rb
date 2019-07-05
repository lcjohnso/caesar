module Reducers
  module HttpReduction
    include HttpOperation
    def self.included(base)
      HttpOperation.configure_validation(base)
    end

    class ReductionFailed < HttpOperation::HttpOperationException; end

    def no_data
      nil
    end

    def operation_failed_type
      ReductionFailed
    end

    def http_reduce(reduction, reducer_inputs)
      result = http_post(reducer_inputs)
      unpack(reduction, result)
    end

    def unpack(reduction, result)
      reduction.tap do |r|
        if result.present? && (result.keys.sort == ['data', 'store'])
          # accept result format { data: {...}, store: {...} }
          r.data = result['data']
          r.store = result['store']
        else
          # accept result format {  _store: {}, ... }
          r.data = result
          if r&.data&.key? '_store'
            r.store = r.data['_store']
            r.data = r.data.except('_store')
          end
        end
      end
    end
  end
end