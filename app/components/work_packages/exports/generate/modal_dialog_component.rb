# frozen_string_literal: true

# -- copyright
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
# ++
require "text/hyphen"

module WorkPackages
  module Exports
    module Generate
      class ModalDialogComponent < ApplicationComponent
        MODAL_ID = "op-work-package-generate-pdf-dialog"
        GENERATE_PDF_FORM_ID = "op-work-packages-generate-pdf-dialog-form"
        include OpTurbo::Streamable
        include OpPrimer::ComponentHelpers

        attr_reader :work_package, :params

        def initialize(work_package:, params:)
          super

          @work_package = work_package
          @params = params
        end

        def default_header_text_right
          "#{work_package.type} ##{work_package.id}"
        end

        def default_footer_text_center
          work_package.subject
        end

        def generate_selects
          [
            {
              name: "hyphenation",
              label: "Hyphenation",
              caption: "Break words between lines to improve text justification and readability.",
              options: hyphenation_options
            },
            {
              name: "paper_size",
              label: I18n.t("export.dialog.pdf.paper_size.label"),
              caption: "The size of the paper to use for the PDF.",
              options: paper_size_options
            }
          ]
        end

        def language_name(locale)
          I18n.translate('cldr.language_name', locale: locale)
        rescue
          nil # not supported language
        end

        def hyphenation_options
          # This is a list of languages that are supported by the hyphenation library
          # https://rubygems.org/gems/text-hyphen
          # The labels are the language names in the language itself (NOT to be put I18n)
          supported_languages = [
            { value: "ca", label: "Català" },
            { value: "cs", label: "Čeština" },
            { value: "da", label: "Dansk" },
            { value: "de", label: "Deutsch" },
            { value: "en_uk", label: "English (UK)" },
            { value: "en_us", label: "English (USA)" },
            { value: "es", label: "Español" },
            { value: "et", label: "Eesti" },
            { value: "eu", label: "Euskara" },
            { value: "fi", label: "Suomi" },
            { value: "fr", label: "Français" },
            { value: "ga", label: "Gaeilge" },
            { value: "hr", label: "Hrvatski" },
            { value: "hu", label: "Magyar" },
            { value: "ia", label: "Interlingua" },
            { value: "id", label: "Indonesia" },
            { value: "is", label: "Ísland" },
            { value: "it", label: "Italiano" },
            { value: "mn", label: "Монгол" },
            { value: "ms", label: "Melayu" },
            { value: "nl", label: "Nederlands" },
            { value: "no", label: "Norsk" },
            { value: "pl", label: "Polski" },
            { value: "pt", label: "Português" },
            { value: "ru", label: "Русский" },
            { value: "sk", label: "Slovenčina" },
            { value: "sv", label: "Svenska" }
          ].sort_by { |item| item[:label] }
          [{ value: "", label: "Off", default: true }].concat(supported_languages)
        end

        def paper_size_options
          [
            { label: "A4", value: "A4", default: true },
            { label: "A3", value: "A3" },
            { label: "A2", value: "A2" },
            { label: "A1", value: "A1" },
            { label: "A0", value: "A0" },
            { label: "Executive", value: "EXECUTIVE" },
            { label: "Folio", value: "FOLIO" },
            { label: "Letter", value: "LETTER" },
            { label: "Tabloid", value: "TABLOID" }
          ]
        end
      end
    end
  end
end
