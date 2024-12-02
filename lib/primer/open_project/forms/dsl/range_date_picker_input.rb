# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      module Dsl
        class RangeDatePickerInput < SingleDatePickerInput
          def derive_datepicker_options(options)
            options.reverse_merge(
              component: "opce-range-date-picker"
            )
          end

          def type
            :range_date_picker
          end
        end
      end
    end
  end
end
