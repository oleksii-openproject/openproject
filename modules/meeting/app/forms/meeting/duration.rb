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

class Meeting::Duration < ApplicationForm
  form do |meeting_form|
    meeting_form.text_field(
      name: :duration,
      type: :number,
      min: 0,
      max: 24,
      step: 0.05,
      value: @value,
      placeholder: Meeting.human_attribute_name(:duration),
      label: Meeting.human_attribute_name(:duration),
      visually_hide_label: false,
      required: true,
      leading_visual: { icon: :stopwatch },
      caption: I18n.t("text_in_hours")
    )
  end

  def initialize(meeting:)
    super()

    @value =
      if meeting.is_a?(RecurringMeeting) && meeting.template
        meeting.template.duration
      else
        meeting.duration
      end
  end
end
