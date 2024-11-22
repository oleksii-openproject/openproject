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

class Project::LifeCycleStepDefinition < ApplicationRecord
  has_many :life_cycle_steps,
           class_name: "Project::LifeCycleStep",
           foreign_key: :definition_id,
           inverse_of: :definition,
           dependent: :destroy
  has_many :projects, through: :life_cycle_steps
  belongs_to :color, optional: false

  validates :name, presence: true
  validates :type, inclusion: { in: %w[Project::StageDefinition Project::GateDefinition], message: :must_be_a_stage_or_gate }

  acts_as_list

  def initialize(*args)
    if instance_of? Project::LifeCycleStepDefinition
      # Do not allow directly instantiating this class
      raise NotImplementedError, "Cannot instantiate the base Project::LifeCycleStepDefinition class directly. " \
                                 "Use Project::StageDefinition or Project::GateDefinition instead."
    end

    super
  end
end
