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

class API::V3::FileLinks::WorkPackagesFileLinksAPI < API::OpenProjectAPI
  helpers do
    def sync_and_convert_relation(file_links)
      sync_result = ::Storages::FileLinkSyncService
                      .new(user: current_user)
                      .call(file_links)
                      .result

      value_list = sync_result
                     .map { |file_link| "(#{file_link.id},'#{file_link.origin_status}')" }
                     .join(",")

      origin_status_attribute = <<-SQL.squish
        LEFT JOIN (VALUES #{value_list}) AS origin_status (id,status) ON origin_status.id = file_links.id
      SQL

      ::Storages::FileLink.where(id: sync_result.map(&:id))
                          .joins(origin_status_attribute)
                          .select("file_links.*, origin_status.status AS origin_status")
    end
  end

  resources :file_links do
    get do
      query = ParamsToQueryService
                .new(::Storages::Storage,
                     current_user,
                     query_class: ::Queries::Storages::FileLinks::FileLinkQuery)
                .call(params)

      unless query.valid?
        message = I18n.t("api_v3.errors.missing_or_malformed_parameter", parameter: "filters")
        raise ::API::Errors::InvalidQuery.new(message)
      end

      relation = if current_user.allowed_in_project?(:view_file_links, @work_package.project)
                   file_links = query.results.where(container_id: @work_package.id,
                                                    container_type: "WorkPackage",
                                                    storage: @work_package.project.storages)

                   if params[:pageSize] == "0"
                     file_links
                   else
                     sync_and_convert_relation(file_links)
                   end
                 else
                   ::Storages::FileLink.none
                 end

      ::API::V3::FileLinks::FileLinkCollectionRepresenter.new(
        relation,
        per_page: params[:pageSize],
        self_link: api_v3_paths.file_links(@work_package.id),
        current_user:
      )
    end

    post &::API::V3::FileLinks::WorkPackagesFileLinksCreateEndpoint
            .new(
              model: ::Storages::FileLink,
              parse_service: Storages::Peripherals::ParseCreateParamsService,
              render_representer: ::API::V3::FileLinks::FileLinkCollectionRepresenter,
              params_modifier: ->(params) do
                params[:container_id] = work_package.id
                params[:container_type] = work_package.class.name
                params
              end
            )
            .mount
  end
end
