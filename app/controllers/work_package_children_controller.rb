# frozen_string_literal: true

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

class WorkPackageChildrenController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::DialogStreamHelper

  before_action :set_work_package

  before_action :authorize # Short-circuit early if not authorized

  before_action :set_child, except: %i[new create]
  before_action :set_relations, except: %i[new create]

  def new
    component = WorkPackageRelationsTab::AddWorkPackageChildDialogComponent
      .new(work_package: @work_package)
    respond_with_dialog(component)
  end

  def create
    target_work_package_id = params[:work_package][:id]
    target_child_work_package = WorkPackage.find(target_work_package_id)

    target_child_work_package.parent = @work_package

    if target_child_work_package.save
      @children = @work_package.children.visible
      @relations = @work_package.relations.visible

      component = WorkPackageRelationsTab::IndexComponent.new(
        work_package: @work_package,
        relations: @relations,
        children: @children
      )
      replace_via_turbo_stream(component:)
      update_flash_message_via_turbo_stream(
        message: I18n.t(:notice_successful_update), scheme: :success
      )
      respond_with_turbo_streams
    end
  end

  def destroy
    @child.parent = nil

    if @child.save
      @work_package.reload
      @children = @work_package.children.visible
      component = WorkPackageRelationsTab::IndexComponent.new(
        work_package: @work_package,
        relations: @relations,
        children: @children
      )
      replace_via_turbo_stream(component:)
      update_flash_message_via_turbo_stream(
        message: I18n.t(:notice_successful_update), scheme: :success
      )

      respond_with_turbo_streams
    end
  end

  private

  def set_work_package
    @work_package = WorkPackage.find(params[:work_package_id])
    @project = @work_package.project
  end

  def set_child
    @child = WorkPackage.find(params[:id])
  end

  def set_relations
    @relations = @work_package.relations.visible
  end
end
