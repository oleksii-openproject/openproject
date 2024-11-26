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

require "spec_helper"

RSpec.describe WorkPackageChildrenController do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:child_work_package) { create(:work_package, parent: work_package, project:) }

  current_user { user }

  describe "GET /work_packages/:work_package_id/children/new" do
    before do
      allow(WorkPackageRelationsTab::AddWorkPackageChildDialogComponent)
        .to receive(:new)
        .with(work_package:)
        .and_call_original
    end

    it "renders the new template" do
      get("new", params: { work_package_id: work_package.id }, as: :turbo_stream)
      expect(response).to be_successful
      expect(WorkPackageRelationsTab::AddWorkPackageChildDialogComponent)
        .to have_received(:new)
        .with(work_package:)
    end
  end

  describe "DELETE /work_packages/:work_package_id/children/:id" do
    before do
      allow(WorkPackageRelationsTab::IndexComponent).to receive(:new).and_call_original
      allow(controller).to receive(:replace_via_turbo_stream).and_call_original
    end

    it "deletes the child relationship" do
      delete("destroy",
             params: { work_package_id: work_package.id,
                       id: child_work_package.id },
             as: :turbo_stream)

      expect(response).to be_successful

      expect(WorkPackageRelationsTab::IndexComponent).to have_received(:new)
        .with(work_package:, relations: [], children: [])
      expect(controller).to have_received(:replace_via_turbo_stream)
        .with(component: an_instance_of(WorkPackageRelationsTab::IndexComponent))
      expect(child_work_package.reload.parent).to be_nil
    end
  end
end
