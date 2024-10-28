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

RSpec.describe "Primerized work package relations tab",
               :cuprite,
               :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:full_wp_view) { Pages::FullWorkPackage.new(work_package) }
  let(:relations_tab) { Components::WorkPackages::Relations.new(work_package) }
  let(:work_packages_page) { Pages::PrimerizedSplitWorkPackage.new(work_package) }
  let(:tabs) { Components::WorkPackages::PrimerizedTabs.new }

  let(:type1) { create(:type) }
  let(:type2) { create(:type) }

  let(:to1) { create(:work_package, type: type1, project:) }
  let(:to2) { create(:work_package, type: type2, project:) }
  let(:from1) { create(:work_package, type: type1, project:) }

  let!(:relation1) do
    create(:relation,
           from: work_package,
           to: to1,
           relation_type: Relation::TYPE_FOLLOWS)
  end
  let!(:relation2) do
    create(:relation,
           from: work_package,
           to: to2,
           relation_type: Relation::TYPE_RELATES)
  end
  let!(:relation3) do
    create(:relation,
           from: from1,
           to: work_package,
           relation_type: Relation::TYPE_BLOCKED)
  end
  let!(:relation4) do
    create(:relation,
           from: to1,
           to: from1,
           relation_type: Relation::TYPE_FOLLOWS)
  end

  current_user { user }

  def label_for_relation_type(relation_type)
    I18n.t("work_package_relations_tab.relations.label_#{relation_type}_plural").capitalize
  end

  before do
    work_packages_page.visit_tab!("relations")
    expect_angular_frontend_initialized
    work_packages_page.expect_subject
    loading_indicator_saveguard
  end

  describe "rendering" do
    it "renders the relations tab" do
      scroll_to_element find(".detail-panel--relations")
      expect(page).to have_css(".detail-panel--relations")

      [relation1, relation2].each do |relation|
        target = relation.to == work_package ? "from" : "to"
        target_relation_type = target == "from" ? relation.reverse_type : relation.relation_type

        expect(page).to have_text(relation.to.type.name.upcase)
        expect(page).to have_text(relation.to.id)
        expect(page).to have_text(relation.to.status.name)
        expect(page).to have_text(relation.to.subject)
        # We reference the reverse type as the "from" node of the relation
        # is the currently visited work package, and the "to" node is the
        # relation target. From the current user's perspective on the work package's
        # page, this is the "reverse" relation.
        expect(page).to have_text(label_for_relation_type(target_relation_type))
      end

      target = relation3.to == work_package ? "from" : "to"
      target_relation_type = target == "from" ? relation3.reverse_type : relation3.relation_type

      expect(page).to have_text(relation3.to.type.name.upcase)
      expect(page).to have_text(relation3.to.id)
      expect(page).to have_text(relation3.to.status.name)
      expect(page).to have_text(relation3.to.subject)
      # We reference the relation type as the "from" node of the relation
      # is not the currently visited work package. From the current user's
      # perspective on the work package's page, this is the "forward" relation.
      expect(page).to have_text(label_for_relation_type(target_relation_type))
    end
  end
end
