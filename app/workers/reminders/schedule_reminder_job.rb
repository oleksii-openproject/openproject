#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Reminders
  class ScheduleReminderJob < ApplicationJob
    queue_with_priority :notification

    def self.schedule(reminder)
      set(wait_until: reminder.remind_at).perform_later(reminder)
    end

    def perform(reminder)
      return if reminder.scheduled?

      create_notification_from_reminder(reminder)
        .on_success { |service_result| ReminderNotification.create!(reminder:, notification: service_result.result) }
    end

    private

    def create_notification_from_reminder(reminder)
      Notifications::CreateService
        .new(user: reminder.creator)
        .call(
          actor_id: reminder.creator_id,
          recipient_id: reminder.creator_id,
          resource: reminder.remindable,
          reason: :reminder
        )
    end
  end
end
