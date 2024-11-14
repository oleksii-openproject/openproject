class AddActiveFlagToProjectLifeCycles < ActiveRecord::Migration[7.1]
  def change
    add_column :project_life_cycles, :active, :boolean, default: false, null: false
  end
end
