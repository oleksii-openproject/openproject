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

class Project::LifeCycleStep < ApplicationRecord
  belongs_to :project, optional: false
  belongs_to :definition,
             optional: false,
             class_name: "Project::LifeCycleStepDefinition"
  has_many :work_packages, inverse_of: :project_life_cycle_step, dependent: :nullify

  delegate :name, to: :definition

  attr_readonly :definition_id, :type

  validates :type, inclusion: { in: %w[Project::Stage Project::Gate], message: :must_be_a_stage_or_gate }

  scope :active, -> { where(active: true) }

  def initialize(*args)
    if instance_of? Project::LifeCycleStep
      # Do not allow directly instantiating this class
      raise NotImplementedError, "Cannot instantiate the base Project::LifeCycleStep class directly. " \
                                 "Use Project::Stage or Project::Gate instead."
    end

    super
  end
end
