class CreateProjectLifeCycles < ActiveRecord::Migration[7.1]
  def change
    create_table :project_life_cycles do |t|
      t.references :project, foreign_key: true
      t.references :life_cycle, foreign_key: true

      t.timestamps
    end
  end
end
