# frozen_string_literal: true

module API
  module V3
    module FileLinks
      class JoinOriginStatusToFileLinksRelation
        # @param [Hash] id_status_map A hash mapping file link IDs to their origin status
        # in the format { 137: "view_allowed", 142: "error" }
        def self.create(id_status_map)
          sanitized_sql = ActiveRecord::Base.send(
            :sanitize_sql_array,
            [origin_status_join(id_status_map.size), *id_status_map.flatten]
          )

          ::Storages::FileLink.where(id: id_status_map.keys)
                              .order(:id)
                              .joins(sanitized_sql)
                              .select("file_links.*, origin_status.status AS origin_status")
        end

        def self.origin_status_join(value_count)
          placeholders = Array.new(value_count).map { "(?,?)" }.join(",")

          <<-SQL.squish
            LEFT JOIN (VALUES #{placeholders}) AS origin_status (id,status) ON origin_status.id = file_links.id
          SQL
        end
      end
    end
  end
end
