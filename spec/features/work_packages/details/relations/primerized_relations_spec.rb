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
               :js, :with_cuprite do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:full_wp_view) { Pages::FullWorkPackage.new(work_package) }
  let(:relations_tab) { Components::WorkPackages::Relations.new(work_package) }
  let(:relations_panel_selector) { ".detail-panel--relations" }
  let(:relations_panel) { find(relations_panel_selector) }
  let(:work_packages_page) { Pages::PrimerizedSplitWorkPackage.new(work_package) }
  let(:tabs) { Components::WorkPackages::PrimerizedTabs.new }

  let(:type1) { create(:type) }
  let(:type2) { create(:type) }

  let(:to1) { create(:work_package, type: type1, project:, start_date: Date.current, due_date: Date.current + 1.week) }
  let(:to2) { create(:work_package, type: type2, project:) }
  let(:to3) { create(:work_package, type: type1, project:) }
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
  let!(:child_wp) do
    create(:work_package,
           parent: work_package,
           type: type1,
           project: project)
  end
  let!(:not_yet_child_wp) do
    create(:work_package,
           type: type1,
           project:)
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
      scroll_to_element relations_panel
      expect(page).to have_css(relations_panel_selector)

      tabs.expect_counter("relations", 4)

      relations_tab.expect_relation(relation1)
      relations_tab.expect_relation(relation2)
      relations_tab.expect_relation(relation3)
    end
  end

  describe "deletion" do
    it "can delete relations" do
      scroll_to_element relations_panel

      relations_tab.remove_relation(relation1)

      expect { relation1.reload }.to raise_error(ActiveRecord::RecordNotFound)

      tabs.expect_counter("relations", 3)
    end

    it "can delete children" do
      scroll_to_element relations_panel

      relations_tab.remove_child(child_wp)
      expect(child_wp.reload.parent).to be_nil

      tabs.expect_counter("relations", 3)
    end
  end

  describe "editing" do
    it "renders an edit form" do
      scroll_to_element relations_panel

      relation_row = relations_tab.expect_relation(relation1)

      relations_tab.add_description_to_relation(relation1, "Discovered relations have descriptions!")

      # Reflects new description
      expect(relation_row).to have_text("Discovered relations have descriptions!")

      # Unchanged
      tabs.expect_counter("relations", 4)

      # Edit again
      relations_tab.edit_relation_description(relation1, "And they can be edited!")

      # Reflects new description
      expect(relation_row).to have_text("And they can be edited!")

      # Unchanged
      tabs.expect_counter("relations", 4)
    end

    it "does not have an edit action for children" do
      scroll_to_element relations_panel

      child_row = relations_panel.find("[data-test-selector='op-relation-row-#{child_wp.id}']")

      within(child_row) do
        page.find("[data-test-selector='op-relation-row-#{child_wp.id}-action-menu']").click
        expect(page).to have_no_css("[data-test-selector='op-relation-row-#{child_wp.id}-edit-button']")
      end
    end
  end

  describe "creating a relation" do
    it "renders the new relation form for the selected type and creates the relation" do
      scroll_to_element relations_panel

      relations_tab.add_relation(type: :follows, to: to3, description: "Discovered relations have descriptions!")
      relations_tab.expect_relation(to3)

      # Bumped by one
      tabs.expect_counter("relations", 5)
    end

    it "does not autocomplete unrelatable work packages" do
      # to1 is already related to work_package as relation1
      # in a successor relation, so it should not be autocompleteable anymore
      # under the "Successor (after)" type
      scroll_to_element relations_panel

      relations_panel.find("[data-test-selector='new-relation-action-menu']").click

      within page.find_by_id("new-relation-action-menu-list") do # Primer appends "list" to the menu id automatically
        click_link_or_button "Successor (after)"
      end

      wait_for_reload

      within "##{WorkPackageRelationsTab::WorkPackageRelationFormComponent::DIALOG_ID}" do
        expect(page).to have_text("Add successor (after)")
        expect(page).to have_button("Add description")

        autocomplete_field = page.find("[data-test-selector='work-package-relation-form-to-id']")
        search_autocomplete(autocomplete_field,
                            query: to1.subject,
                            results_selector: "body")
        expect_no_ng_option(autocomplete_field,
                            to1.subject,
                            results_selector: "body")
      end
    end
  end

  describe "attaching a child" do
    it "renders the new child form and creates the child relationship" do
      scroll_to_element relations_panel

      tabs.expect_counter("relations", 4)

      relations_tab.add_existing_child(not_yet_child_wp)
      relations_tab.expect_child(not_yet_child_wp)

      # Bumped by one
      tabs.expect_counter("relations", 5)
    end
  end
end
