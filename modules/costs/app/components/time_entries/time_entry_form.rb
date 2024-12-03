module TimeEntries
  class TimeEntryForm < ApplicationForm
    include CustomFields::CustomFieldRendering

    form do |f|
      f.autocompleter(
        name: :user_id,
        label: TimeEntry.human_attribute_name(:user),
        autocomplete_options: {
          defaultData: true,
          component: "opce-user-autocompleter",
          url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
          filters: [{ name: "type", operator: "=", values: %w[User Group] },
                    { name: "member", operator: "=", values: [model.project_id] },
                    { name: "status", operator: "=", values: [Principal.statuses[:active], Principal.statuses[:invited]] }],
          searchKey: "any_name_attribute",
          resource: "principals",
          focusDirectly: false,
          multiple: false,
          appendTo: "#time-entry-dialog",
          disabled: !show_user_field?
        }
      )

      f.text_field name: :spent_on, label: "Date"

      f.group(layout: :horizontal) do |g|
        g.text_field name: :start_time,
                     label: "Start time",
                     data: { "time-entry-target" => "startTimeInput" }

        g.text_field name: :end_time,
                     label: "Finish time",
                     data: { "time-entry-target" => "endTimeInput" }
      end

      f.text_field name: :hours,
                   label: "Hours",
                   data: { "time-entry-target" => "hoursInput" }

      if show_work_package_field?
        f.work_package_autocompleter name: :work_package_id,
                                     label: "Work package",
                                     autocomplete_options: {
                                       append_to: "#time-entry-dialog"

                                     }
      end

      f.text_field name: :activity, label: "Activity"

      f.text_field name: :comments, label: "Comments"

      render_custom_fields(form: f)
    end

    def additional_custom_field_input_arguments
      { wrapper_id: "#time-entry-dialog" }
    end

    private

    delegate :project, :work_package, to: :model

    def custom_fields
      @custom_fields ||= model.available_custom_fields
    end

    def show_work_package_field?
      work_package.blank?
    end

    def show_user_field?
      # Only allow setting a different user, when the user has the
      # permission to log time for others in the project
      User.current.allowed_in_project?(:log_time, project)
    end

    def show_start_and_end_time_fields?
      TimeEntry.can_track_start_and_end_time?
    end
  end
end
