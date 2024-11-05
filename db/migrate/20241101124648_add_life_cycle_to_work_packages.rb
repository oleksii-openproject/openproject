class AddLifeCycleToWorkPackages < ActiveRecord::Migration[7.1]
  def change
    add_reference :work_packages, :life_cycle, foreign_key: { to_table: :life_cycles }, null: true
  end
end
