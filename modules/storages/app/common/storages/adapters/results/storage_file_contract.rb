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
    module Results
      class StorageFileContract < Dry::Validation::Contract
        params do
          before(:value_coercer) do |input|
            input.to_h.compact
          end

          required(:id).filled(:string)
          required(:name).filled(:string)
          optional(:size).filled(:integer, gteq?: 0)
          optional(:mime_type).filled(:string)
          optional(:created_at).filled(:time)
          optional(:last_modified_at).filled(:time)
          optional(:created_by_name).filled(:string)
          optional(:last_modified_by_name).filled(:string)
          optional(:location).filled(:string, format?: /^\//)
          # Permissions are either array or string. We should standardise this
          optional(:permissions).value { array? | str? }
        end
      end
    end
  end
end
