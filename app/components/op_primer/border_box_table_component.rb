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

module OpPrimer
  class BorderBoxTableComponent < TableComponent
    include ComponentHelpers

    class << self
      # Declares columns to be shown in the mobile table
      #
      # Use it in subclasses like so:
      #
      #     columns :name, :description
      #
      #     mobile_columns :name
      #
      # This results in the description columns to be hidden on mobile
      def mobile_columns(*names)
        return @mobile_columns || columns if names.empty?

        @mobile_columns = names.map(&:to_sym)
      end

      # Declares which columns to be rendered with a label
      #
      #     mobile_labels :name
      #
      # This results in the description columns to be hidden on mobile
      def mobile_labels(*names)
        return @mobile_labels if names.empty?

        @mobile_labels = names.map(&:to_sym)
      end

      # Declare wide columns, that will result in a grid column span of 3
      #
      #     column_grid_span :title
      #
      def wide_columns(*names)
        return Array(@wide_columns) if names.empty?

        @wide_columns = names.map(&:to_sym)
      end
    end

    delegate :mobile_columns, :mobile_labels,
             to: :class

    def wide_column?(column)
      self.class.wide_columns.include?(column)
    end

    def header_args(_column)
      {}
    end

    def column_title(name)
      header = headers.find { |h| h[0] == name }
      header ? header[1][:caption] : nil
    end

    def header_classes(column)
      classes = [heading_class]
      classes << "op-border-box-grid--wide-column" if wide_column?(column)

      classes.join(" ")
    end

    def heading_class
      "op-border-box-grid--heading"
    end

    # Default grid class with equal weights
    def grid_class
      "op-border-box-grid"
    end

    def has_actions?
      false
    end

    def sortable?
      false
    end

    def render_blank_slate
      render(Primer::Beta::Blankslate.new(border: false)) do |component|
        component.with_visual_icon(icon: blank_icon, size: :medium) if blank_icon
        component.with_heading(tag: :h2) { blank_title }
        component.with_description { blank_description }
      end
    end

    def mobile_title
      raise ArgumentError, "Need to provide a mobile table title"
    end

    def blank_title
      I18n.t(:label_nothing_display)
    end

    def blank_description
      I18n.t(:no_results_title_text)
    end

    def blank_icon
      nil
    end
  end
end
