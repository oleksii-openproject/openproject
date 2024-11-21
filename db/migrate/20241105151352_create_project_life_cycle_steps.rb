class CreateProjectLifeCycleSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :project_life_cycle_steps do |t|
      t.string :type
      t.date :start_date
      t.date :end_date
      t.boolean :active, default: false, null: false
      t.integer :position, default: 1, null: true
      t.references :project, foreign_key: true
      t.references :definition, foreign_key: { to_table: :project_life_cycle_step_definitions }

      t.timestamps
    end
  end
end
