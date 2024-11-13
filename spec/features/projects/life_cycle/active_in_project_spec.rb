# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require "spec_helper"

RSpec.describe "Projects life cycle settings", :js, :with_cuprite do
  shared_let(:project) { create(:project) }

  shared_let(:user_with_permission) do
    create(:user,
           member_with_permissions: {
             # TODO: change to specific permission
             project: %w[
               select_project_life_cycle
             ]
           })
  end

  shared_let(:initiating_stage) { create(:stage, name: "Initiating") }
  shared_let(:read_to_execute_gate) { create(:gate, name: "Read to Execute") }
  shared_let(:executing_stage) { create(:stage, name: "Executing") }
  shared_let(:read_to_close_gate) { create(:gate, name: "Read to Close") }
  shared_let(:closing_stage) { create(:stage, name: "Closing") }

  let(:project_lifecycle_page) { Pages::Projects::Settings::LifeCycle.new(project) }

  context "with sufficient permissions" do
    current_user { user_with_permission }

    it "allows toggling the active/inactive state of lifecycle elements" do
      project_lifecycle_page.visit!
    end
  end
end
