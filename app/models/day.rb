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

class Day < TablelessModel
  attribute :id, :integer, default: nil
  attribute :date, :date, default: nil
  attribute :day_of_week, :integer, default: nil
  attribute :working, :boolean, default: true

  delegate :name, to: :week_day, allow_nil: true

  def non_working_days
    @non_working_days ||= NonWorkingDay.where(date: date)
  end

  class << self
    def for_this_month
      today = Time.zone.today
      from = today.at_beginning_of_month
      to = today.next_month.at_end_of_month

      from_range(from: from, to: to)
    end

    def from_range(from:, to:)
      range = from.to_date..to.to_date
      non_working_days = NonWorkingDay.where(date: range).pluck(:date)

      range.map do |date|
        new(
          id: date.strftime("YYYYMMDD").to_i,
          date: date,
          day_of_week: date.wday,
          working: date.wday.in?(Setting.working_days) && non_working_days.exclude?(date)
        )
      end
    end

    def last_working
      # Look up only from 8 days ago, because the Setting.working_days must have at least 1 working weekday.
      from_range(from: 8.days.ago, to: Time.zone.yesterday).reverse.find(&:working)
    end
  end

  def week_day
    WeekDay.new(day: day_of_week)
  end
end
