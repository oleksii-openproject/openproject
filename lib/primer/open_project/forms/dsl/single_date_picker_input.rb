# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class SingleDatePickerInput < Primer::Forms::Dsl::TextFieldInput
          attr_reader :datepicker_options

          def initialize(name:, label:, datepicker_options:, **system_arguments)
            @datepicker_options = derive_datepicker_options(datepicker_options)

            super(name:, label:, **system_arguments)
          end

          def derive_datepicker_options(options)
            options.reverse_merge(
              component: "opce-single-date-picker"
            )
          end

          def to_component
            DatePicker.new(input: self, datepicker_options:)
          end

          def type
            :single_date_picker
          end
        end
      end
    end
  end
end
