class CreateReminders < ActiveRecord::Migration[7.1]
  def change
    create_table :reminders do |t|
      t.references :remindable, polymorphic: true, null: false
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.datetime :remind_at, null: false
      t.string :job_id
      t.text :notes

      t.timestamps
    end
  end
end
