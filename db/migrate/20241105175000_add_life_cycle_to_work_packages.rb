class AddLifeCycleToWorkPackages < ActiveRecord::Migration[7.1]
  def change
    add_reference :work_packages, :project_life_cycle, foreign_key: true, null: true
  end
end
