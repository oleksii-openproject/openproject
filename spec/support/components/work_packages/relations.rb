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

require "support/components/autocompleter/ng_select_autocomplete_helpers"

module Components
  module WorkPackages
    class Relations
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers
      include RSpec::Wait
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      attr_reader :work_package

      def initialize(work_package)
        @work_package = work_package
      end

      def find_row(relatable)
        page.find("[data-test-selector='op-relation-row-#{relatable.id}']")
      end

      def find_some_row(text:)
        page.find("[data-test-selector^='op-relation-row']", text:)
      end

      def expect_no_row(relatable)
        if relatable.is_a?(Relation)
          expect(page).to have_no_css("[data-test-selector='op-relation-row-#{relatable.to.id}']")
        else
          expect(page).to have_no_css("[data-test-selector='op-relation-row-#{relatable.id}']")
        end
      end

      def remove_relation(relatable)
        relatable_row = find_row(relatable)

        within(relatable_row) do
          page.find("[data-test-selector='op-relation-row-#{relatable.id}-action-menu']").click
          page.find("[data-test-selector='op-relation-row-#{relatable.id}-delete-button']").click
        end

        # Expect relation to be gone
        expect_no_row(relatable)
      end

      def add_relation(type:, to:)
        i18n_namespace = "#{WorkPackageRelationsTab::IndexComponent::I18N_NAMESPACE}.relations"
        # Open create form

        SeleniumHubWaiter.wait
        page.find("[data-test-selector='new-relation-action-menu']").click

        label_text_for_relation_type = I18n.t("#{i18n_namespace}.label_#{type}_singular")
        within page.find_by_id("new-relation-action-menu-list") do # Primer appends "list" to the menu id automatically
          click_link_or_button label_text_for_relation_type.capitalize
        end

        # Labels to expect
        modal_heading_label = "Add #{label_text_for_relation_type}"
        expect(page).to have_text(modal_heading_label)

        # Enter the query and select the child
        autocomplete_field = page.find("[data-test-selector='work-package-relation-form-to-id']")
        select_autocomplete(autocomplete_field,
                            query: to.subject,
                            results_selector: "body")

        click_link_or_button "Save"

        label_text_for_relation_type_pluralized = I18n.t("#{i18n_namespace}.label_#{type}_plural").capitalize

        wait_for { page }.to have_no_text(modal_heading_label)
        wait_for { page }.to have_text(label_text_for_relation_type_pluralized)

        new_relation = work_package.reload.relations.last
        target_wp = new_relation.other_work_package(work_package)
        find_row(target_wp)
      end

      def expect_relation(relatable)
        find_row(relatable)
      end

      def expect_relation_by_text(text)
        find_some_row(text:)
      end

      def expect_no_relation(relatable)
        expect_no_row(relatable)
      end

      def add_parent(query, work_package)
        # Open the parent edit
        SeleniumHubWaiter.wait
        find(".wp-relation--parent-change").click

        # Enter the query and select the child
        SeleniumHubWaiter.wait
        autocomplete = find("[data-test-selector='wp-relations-autocomplete']")
        select_autocomplete autocomplete,
                            query:,
                            results_selector: ".ng-dropdown-panel-items",
                            select_text: work_package.id
      end

      def expect_parent(work_package)
        expect(page).to have_css '[data-test-selector="op-wp-breadcrumb-parent"]',
                                 text: work_package.subject,
                                 wait: 10
      end

      def expect_no_parent
        expect(page).to have_no_css '[data-test-selector="op-wp-breadcrumb-parent"]', wait: 10
      end

      def remove_parent
        SeleniumHubWaiter.wait
        find(".wp-relation--parent-remove").click
      end

      def open_children_autocompleter
        retry_block do
          next if page.has_selector?(".wp-relations--children .ng-input input")

          SeleniumHubWaiter.wait
          find('[data-test-selector="op-wp-inline-create-reference"]',
               text: I18n.t("js.relation_buttons.add_existing_child")).click

          # Security check to be sure that the autocompleter has finished loading
          page.find ".wp-relations--children .ng-input input"
        end
      end

      def children_table
        page.find("[data-test-selector='op-relation-group-children']")
      end

      def add_existing_child(work_package)
        page.find("[data-test-selector='new-relation-action-menu']").click

        within page.find_by_id("new-relation-action-menu-list") do # Primer appends "list" to the menu id automatically
          click_link_or_button "Child"
        end

        within "##{WorkPackageRelationsTab::AddWorkPackageChildFormComponent::DIALOG_ID}" do
          autocomplete_field = page.find("[data-test-selector='work-package-child-form-id']")
          select_autocomplete(autocomplete_field,
                              query: work_package.subject,
                              results_selector: "body")

          click_link_or_button "Save"
        end
      end

      def expect_child(work_package)
        expect_row(work_package)
      end

      def expect_not_child(work_package)
        expect_no_row(work_package)
      end

      def relations_group
        page.find_by_id("work-package-relations-tab-content")
      end

      def remove_child(work_package)
        child_wp_row = find_row(work_package)

        within(child_wp_row) do
          page.find("[data-test-selector='op-relation-row-#{work_package.id}-action-menu']").click
          page.find("[data-test-selector='op-relation-row-#{work_package.id}-delete-button']").click
        end

        expect_no_row(work_package)
      end
    end
  end
end
