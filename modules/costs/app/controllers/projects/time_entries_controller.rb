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

module Projects
  class TimeEntriesController < ApplicationController
    include OpTurbo::ComponentStream
    include OpTurbo::DialogStreamHelper

    before_action :require_login
    before_action :find_project_by_project_id

    authorization_checked! :dialog, :create, :update

    def dialog
      @time_entry = if params[:time_entry_id]
                      # TODO: Properly handle authorization
                      TimeEntry.find_by(id: params[:time_entry_id])
                    else
                      TimeEntry.new(project: @project, user: User.current)
                    end
    end

    def create
      puts "*" * 100
      pp(permitted_params.time_entries)
      puts "*" * 100
    end

    def update
      puts "*" * 100
      pp(permitted_params.time_entries)
      puts "*" * 100
    end
  end
end
