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

require "dry/container"

module Storages
  module Adapters
    class Registry
      extend Dry::Container::Mixin

      # Extracts the known_providers from the registered keys
      # @return [Array<String>]
      def self.known_providers
        keys.map { _1.split(".").first }.uniq
      end

      namespace("one_drive") do
        namespace("commands") do
          register("create_folder", -> { folder })
        end
        namespace("contracts") do
          register(:storage, "Contract")
        end
      end

      class Resolver < Dry::Container::Resolver
        include TaggedLogging

        def call(container, key)
          with_tagged_logger("Registry") do
            info "Resolving #{key}"
            super
          end
        rescue Dry::Container::KeyError
          error = Errors.registry_error_for(key)

          with_tagged_logger("Registry") { error error.message }
          raise error
        end
      end

      config.resolver = Resolver.new

      # Need to make this dynamic to ease new providers to be registered
      import Providers::OneDrive::Registry
    end
  end
end
