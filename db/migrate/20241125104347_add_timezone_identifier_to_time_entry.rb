class AddTimezoneIdentifierToTimeEntry < ActiveRecord::Migration[7.1]
  def change
    add_column :time_entries, :time_zone, :string
    add_column :time_entry_journals, :time_zone, :string
  end
end
