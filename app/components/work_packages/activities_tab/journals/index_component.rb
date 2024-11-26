# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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

module WorkPackages
  module ActivitiesTab
    module Journals
      class IndexComponent < ApplicationComponent
        MAX_RECENT_JOURNALS = 30

        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable
        include WorkPackages::ActivitiesTab::SharedHelpers

        def initialize(work_package:, filter: :all, deferred: false)
          super

          @work_package = work_package
          @filter = filter
          @deferred = deferred
        end

        private

        attr_reader :work_package, :filter, :deferred

        def insert_target_modified?
          true
        end

        def insert_target_modifier_id
          "work-package-journal-days"
        end

        def journal_sorting_desc?
          journal_sorting == "desc"
        end

        def base_journals
          work_package
            .journals
            .includes(
              :user,
              :customizable_journals,
              :attachable_journals,
              :storable_journals,
              :notifications
            )
            .reorder(version: journal_sorting)
            .with_sequence_version
        end

        def journals
          API::V3::Activities::ActivityEagerLoadingWrapper.wrap(base_journals)
        end

        def recent_journals
          recent_ones = if journal_sorting_desc?
                          base_journals.first(MAX_RECENT_JOURNALS)
                        else
                          base_journals.last(MAX_RECENT_JOURNALS)
                        end

          API::V3::Activities::ActivityEagerLoadingWrapper.wrap(recent_ones)
        end

        def older_journals
          older_ones = if journal_sorting_desc?
                         base_journals.offset(MAX_RECENT_JOURNALS)
                       else
                         total = base_journals.count
                         limit = [total - MAX_RECENT_JOURNALS, 0].max
                         base_journals.limit(limit)
                       end

          API::V3::Activities::ActivityEagerLoadingWrapper.wrap(older_ones)
        end

        def journal_with_notes
          base_journals.where.not(notes: "")
        end

        def wp_journals_grouped_emoji_reactions
          @wp_journals_grouped_emoji_reactions ||= Journal.grouped_work_package_journals_emoji_reactions(work_package)
        end

        def empty_state?
          filter == :only_comments && journal_with_notes.empty?
        end

        def inner_container_margin_bottom
          if journal_sorting_desc?
            3
          else
            0
          end
        end
      end
    end
  end
end
