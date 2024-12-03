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

module Storages
  module Adapters
    module Providers
      module OneDrive
        module Queries
          class FileInfoQuery < Base
            FIELDS = %w[id name fileSystemInfo file folder size createdBy lastModifiedBy parentReference].freeze

            def self.call(storage:, auth_strategy:, input_data:)
              new(storage).call(auth_strategy:, input_data:)
            end

            def call(auth_strategy:, input_data:)
              base_query = Authentication[auth_strategy].call(storage: @storage) do |http|
                drive_item_query.call(http:, drive_item_id: input_data.file_id, fields: FIELDS)
              end

              result = base_query.fmap { |json| storage_file_info(json) }

              result.or do |error|
                return Failure(error) unless error.code == :not_found && auth_strategy.value!.user.present?

                admin_query(input_data.file_id)
              end
            end

            private

            def admin_query(file_id)
              Authentication[userless_strategy].call(storage: @storage) do |http|
                drive_item_query.call(http:, drive_item_id: file_id, fields: FIELDS)
                                .bind { |json| storage_file_info(json, status: "forbidden", status_code: 403) }
              end
            end

            def userless_strategy = Registry.resolve("one_drive.authentication.userless").call

            def drive_item_query
              @drive_item_query ||= DriveItemQuery.new(@storage)
            end

            def storage_file_info(json, status: "ok", status_code: 200)
              StorageFileTransformer.new.transform_file_info({ status:, status_code: }.merge(json))
            end
          end
        end
      end
    end
  end
end
