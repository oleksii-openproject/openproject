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
  class CreateService < ::BaseServices::Create
    include WithTemplate

    protected

    def after_perform(call)
      return call unless call.success?

      recurring_meeting = call.result
      call.merge! create_meeting_template(recurring_meeting) if call.success?
      schedule_init_job(recurring_meeting) if call.success?

      call
    end

    ##
    # We want to automatically schedule the next occurrence
    # AFTER the first occurrence has passed.
    # We do not create initially as you still need to update the template.
    def schedule_init_job(recurring_meeting)
      first_occurrence = recurring_meeting.first_occurrence
      return if first_occurrence.nil?

      ::RecurringMeetings::InitNextOccurrenceJob
        .set(wait_until: first_occurrence.to_time)
        .perform_later(recurring_meeting)
    end

    def create_meeting_template(recurring_meeting)
      template = StructuredMeeting.new(@template_params)
      template.project = recurring_meeting.project
      template.template = true
      template.recurring_meeting = recurring_meeting
      template.author = user

      ServiceResult.new(success: template.save, errors: template.errors)
    end
  end
end
