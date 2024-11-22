class CreateReminderNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :reminder_notifications do |t|
      t.references :reminder, foreign_key: true
      t.references :notification, foreign_key: true

      t.timestamps
    end

    add_index :reminder_notifications, :notification_id,
              unique: true,
              name: "index_reminder_notifications_unique"
  end
end
