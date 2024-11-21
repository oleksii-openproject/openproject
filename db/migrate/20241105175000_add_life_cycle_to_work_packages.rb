class AddLifeCycleToWorkPackages < ActiveRecord::Migration[7.1]
  def change
    add_reference :work_packages,
                  :life_cycle_step,
                  foreign_key: { to_table: :project_life_cycle_steps },
                  null: true
  end
end
