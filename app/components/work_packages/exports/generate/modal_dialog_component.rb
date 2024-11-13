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

        def generate_selects
          [
            {
              name: "hyphenation",
              label:'Hyphenation',
              caption: 'Break words between lines to improve text justification and readability.',
              options: hyphenation_options
            },
            {
              name: "paper_size",
              label: I18n.t("export.dialog.pdf.paper_size.label"),
              caption: 'The size of the paper to use for the PDF.',
              options: paper_size_options
            }
          ]
        end

        def hyphenation_options
            # This is a list of languages that are supported by the hyphenation library
            # https://rubygems.org/gems/text-hyphen
            [
              { value: "", label: 'Off', default: true },
              { value: "ca", label: 'Catalan' },
              { value: "cs", label: 'Czech' },
              { value: "da", label: 'Danish' },
              { value: "de", label: 'German' },
              { value: "en_uk", label: 'English (UK)' },
              { value: "en_us", label: 'English (USA)' },
              { value: "es", label: 'Spanish' },
              { value: "et", label: 'Estonian' },
              { value: "eu", label: 'Basque' },
              { value: "fi", label: 'Finnish' },
              { value: "fr", label: 'French' },
              { value: "ga", label: 'Irish' },
              { value: "hr", label: 'Croatian' },
              { value: "hu", label: 'Hungarian' },
              { value: "ia", label: 'Interlingua' },
              { value: "id", label: 'Indonesian' },
              { value: "is", label: 'Icelandic' },
              { value: "it", label: 'Italian' },
              { value: "mn", label: 'Mongolian' },
              { value: "ms", label: 'Malay' },
              { value: "nl", label: 'Dutch' },
              { value: "no", label: 'Norwegian' },
              { value: "pl", label: 'Polish' },
              { value: "pt", label: 'Portuguese' },
              { value: "ru", label: 'Russian' },
              { value: "sk", label: 'Slovak' },
              { value: "sv", label: 'Swedish' }
            ]
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
