class AddStartEndTimesToTimeEntries < ActiveRecord::Migration[7.1]
  def change
    # TODO: Figure out if we need to use any timezone conversion in the generated columns

    # order of changes matter, so we cannot use bulk here
    change_table :time_entries do |t| # rubocop:disable Lint/RedundantCopDisableDirective,Rails/BulkChangeTable
      t.integer :start_time, null: true
      t.integer :end_time, null: true

      t.virtual :start_timestamp,
                type: :datetime,
                as: "CASE WHEN start_time IS NOT NULL THEN spent_on::timestamp + INTERVAL '1 minute' * start_time ELSE NULL END",
                stored: true

      t.virtual :end_timestamp,
                type: :datetime,
                as: "CASE WHEN end_time IS NOT NULL THEN spent_on::timestamp + INTERVAL '1 minute' * end_time ELSE NULL END",
                stored: true
    end

    change_table :time_entry_journals do |t| # rubocop:disable Lint/RedundantCopDisableDirective,Rails/BulkChangeTable
      t.integer :start_time, null: true
      t.integer :end_time, null: true

      t.virtual :start_timestamp,
                type: :datetime,
                as: "CASE WHEN start_time IS NOT NULL THEN spent_on::timestamp + INTERVAL '1 minute' * start_time ELSE NULL END",
                stored: true

      t.virtual :end_timestamp,
                type: :datetime,
                as: "CASE WHEN end_time IS NOT NULL THEN spent_on::timestamp + INTERVAL '1 minute' * end_time ELSE NULL END",
                stored: true
    end
  end
end
