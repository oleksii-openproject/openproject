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

module RecurringMeetings
  class InitNextOccurrenceJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { self.class.unique_key(arguments.first) }
    )

    def self.unique_key(recurring_meeting)
      "RecurringMeetings::InitNextOccurrenceJob-#{recurring_meeting.id}"
    end

    attr_accessor :recurring_meeting

    def perform(recurring_meeting)
      self.recurring_meeting = recurring_meeting

      if next_scheduled_time.nil?
        Rails.logger.debug { "Meeting series #{recurring_meeting} is ending." }
        return
      end

      # Schedule the next occurrence, if not instantiated
      check_next_occurrence
    rescue StandardError => e
      Rails.logger.error { "Error while initializing next occurrence for series ##{recurring_meeting}: #{e.message}" }
    ensure
      schedule_next_job
    end

    private

    def check_next_occurrence
      if next_occurrence_instantiated?
        Rails.logger.debug { "Will not create next occurrence for series #{recurring_meeting} as already instantiated" }
        return
      end

      if next_occurrence_cancelled?
        Rails.logger.debug { "Will not create next occurrence for series #{recurring_meeting} is already cancelled" }
        return
      end

      init_meeting
    end

    def init_meeting
      call = ::RecurringMeetings::InitOccurrenceService
        .new(user: User.system, recurring_meeting:)
        .call(start_time: next_scheduled_time)

      call.on_success do
        Rails.logger.debug { "Initialized occurrence for series ##{recurring_meeting} at #{next_scheduled_time}" }
      end

      call.on_failure do
        Rails.logger.error do
          "Could not create next occurrence for series ##{recurring_meeting}: #{call.message}"
        end
      end
    end

    ##
    # Schedule when this job should be run the next time
    def schedule_next_job
      self
        .class
        .set(wait_until: next_scheduled_time)
        .perform_later(recurring_meeting)
    end

    ##
    # Return if there is already an instantiated upcoming meeting
    def next_occurrence_instantiated?
      recurring_meeting
        .scheduled_instances
        .where.not(meeting_id: nil)
        .exists?(start_time: next_scheduled_time)
    end

    ##
    # Return if the next occurrence is cancelled
    def next_occurrence_cancelled?
      recurring_meeting
        .scheduled_instances
        .where(cancelled: true)
        .exists?(start_time: next_scheduled_time)
    end

    def next_scheduled_time
      return @next_scheduled_time if defined?(@next_scheduled_time)

      @next_scheduled_time = recurring_meeting.next_occurrence&.to_time
    end
  end
end
