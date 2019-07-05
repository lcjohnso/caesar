require 'csv'

module Exporters
  class UnknownExporter < StandardError; end

  class CsvExporter
    attr_reader :resource_id, :resource_type, :user_id, :subgroup, :requested_data

    def initialize(params)
      @resource_id = params[:resource_id]
      @resource_type = params[:resource_type]
      @user_id = params[:user_id]
      @subgroup = params[:subgroup]
      @requested_data = params[:requested_data]
    end

    def dump(path=nil, estimated_count: nil)
      if path.blank?
        path = "tmp/#{get_topic.name.demodulize.underscore.pluralize}_#{resource_id}.csv"
      end

      items = get_items
      total = estimated_count || 0
      progress = 0

      CSV.open(path, "wb",
        :write_headers => true,
        :headers => get_csv_headers) do |csv|
        items.find_each do |item|
          csv << extract_row(item)
          progress += 1
          yield(progress, total) if block_given?

          # let someone else use the CPU for a bit to try to appease docker
          # https://stackoverflow.com/questions/36753094/sleep-0-has-special-meaning
          sleep(0) unless progress % 1000
        end
      end
    end

    def get_csv_headers
      get_model_cols + get_unique_json_cols.map{|col| "data.#{col}"}
    end

    def extract_row(source_row)
      model_cols = get_model_cols
      json_cols = get_unique_json_cols

      string_source = source_row.attributes.stringify_keys
      model_values = model_cols.map{ |col| format_item(string_source[col]) }
      json_values = json_cols.map{ |col| format_item(source_row[:data][col]) }
      model_values + json_values
    end

    private

    def format_item(item)
      return "" unless item.present?

      case item
        when Integer, Float, String, TrueClass, FalseClass then item
        when Array then item.to_json
        when Hash then item.to_json
        when DateTime, ActiveSupport::TimeWithZone then item
      end
    end

    def get_topic
      requested_data.camelcase.singularize.constantize
    end

    def get_items
      if get_topic == Extract
        find_hash = { workflow_id: resource_id }
      elsif get_topic == SubjectReduction
        find_hash = { reducible_id: resource_id, reducible_type: resource_type }
      elsif get_topic == UserReduction
        find_hash = { reducible_id: resource_id, reducible_type: resource_type }
      end

      if get_topic != SubjectReduction
        find_hash[:user_id] = user_id unless user_id.blank?
      end

      find_hash[:subgroup] = subgroup unless subgroup.blank?

      get_topic.where(find_hash)
    end

    def get_model_cols
      @model_cols ||= get_topic.attribute_names - ["data", "store"]
    end

    def get_unique_json_cols
      @unique_json_cols ||= get_items
                              .where("jsonb_typeof(data)='object'")
                              .select("DISTINCT(jsonb_object_keys(data)) AS key")
                              .map(&:key)
    end

  end
end
