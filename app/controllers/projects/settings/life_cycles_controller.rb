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

  before_action :deny_access_on_feature_flag

  before_action :load_life_cycle_definitions, only: %i[show enable_all disable_all]

  menu_item :settings_life_cycles

  def show; end

  def toggle
    step_params = params
                    .require(:project_life_cycle)
                    .permit(:definition_id, :type)
                    .to_h
                    .symbolize_keys
                    .merge(active: params["value"] == "1")

    upsert_one_step(**step_params)
  end

  def disable_all
    upsert_all_steps(active: false)

    redirect_to action: :show
  end

  def enable_all
    upsert_all_steps(active: true)

    redirect_to action: :show
  end

  private

  def load_life_cycle_definitions
    @life_cycle_definitions = Project::LifeCycleStepDefinition.all
  end

  def deny_access_on_feature_flag
    deny_access unless OpenProject::FeatureDecisions.stages_and_gates_active?
  end

  def upsert_one_step(definition_id:, type:, active: true)
    upsert_all(
      [{
        project_id: @project.id,
        definition_id:,
        active:,
        type: project_type_for_definition_type(type)
      }]
    )
  end

  def upsert_all_steps(active: true)
    upsert_all(
      @life_cycle_definitions.map do |definition|
        {
          project_id: @project.id,
          definition_id: definition.id,
          active:,
          type: project_type_for_definition_type(definition.type)
        }
      end
    )
  end

  def upsert_all(upserted_steps)
    Project::LifeCycleStep.upsert_all(
      upserted_steps,
      unique_by: %i[project_id definition_id]
    )
  end

  def project_type_for_definition_type(definition_type)
    case definition_type
    when Project::StageDefinition.name
      Project::Stage
    when Project::GateDefinition.name
      Project::Gate
    else
      raise NotImplementedError, "Unknown life cycle definition type"
    end
  end
end
