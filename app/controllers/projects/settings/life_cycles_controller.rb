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

class Projects::Settings::LifeCyclesController < Projects::SettingsController
  include OpTurbo::ComponentStream

  before_action :load_life_cycle_elements, only: %i[show]
  before_action :load_or_create_life_cycle_element, only: %i[toggle]

  menu_item :settings_life_cycles

  def show; end

  def toggle
    @life_cycle_element.toggle!(:active)
  end

  private

  def load_life_cycle_elements
    @life_cycle_elements = Project::LifeCycleStepDefinition.all
  end

  def load_or_create_life_cycle_element
    element_params = params.require(:project_life_cycle).permit(:definition_id, :project_id, :type)

    klass = case element_params.delete(:type)
            when Project::StageDefinition.name
              Project::Stage
            when Project::GateDefinition.name
              Project::Gate
            else
              raise NotImplementedError, "Unknown life cycle element type"
            end

    @life_cycle_element = klass.find_or_create_by(element_params)
  end
end
