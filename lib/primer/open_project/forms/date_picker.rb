# frozen_string_literal: true

module Primer
  module OpenProject
    module Forms
      # :nodoc:
      class DatePicker < Primer::Forms::TextField
        include AngularHelper

        def initialize(input:, datepicker_options:)
          super(input:)
          @datepicker_options = datepicker_options
        end
      end
    end
  end
end
