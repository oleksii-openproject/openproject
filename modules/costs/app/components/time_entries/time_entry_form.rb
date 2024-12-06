module TimeEntries
  class TimeEntryForm < ApplicationForm
    include CustomFields::CustomFieldRendering

    form do |f|
      f.autocompleter(
        name: :user_id,
        label: TimeEntry.human_attribute_name(:user),
        required: true,
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

      f.single_date_picker name: :spent_on,
                           type: "date",
                           required: true,
                           datepicker_options: { inDialog: true },
                           label: TimeEntry.human_attribute_name(:spent_on)

      f.group(layout: :horizontal) do |g|
        # TODO: Add a time picker based on the date picker linked above
        g.text_field name: :start_time,
                     required: true,
                     label: TimeEntry.human_attribute_name(:start_time),
                     value: model.start_timestamp&.strftime("%H:%M"),
                     data: { "time-entry-target" => "startTimeInput" }

        g.text_field name: :end_time,
                     required: true,
                     label: TimeEntry.human_attribute_name(:end_time),
                     value: model.end_timestamp&.strftime("%H:%M"),
                     data: { "time-entry-target" => "endTimeInput" }
      end

      f.text_field name: :hours,
                   required: true,
                   label: TimeEntry.human_attribute_name(:hours),
                   data: { "time-entry-target" => "hoursInput" }

      f.work_package_autocompleter name: :work_package_id,
                                   label: TimeEntry.human_attribute_name(:work_package),
                                   autocomplete_options: {
                                     focusDirectly: false,
                                     append_to: "#time-entry-dialog",
                                     filters: [
                                       { name: "project_id", operator: "=", values: [model.project_id] }
                                     ]
                                   }

      f.select_list name: :activity_id, label: TimeEntry.human_attribute_name(:activity), include_blank: true do |list|
        activities.each do |activity|
          selected = (model.activity_id == activity.id) || (model.activity_id.blank? && activity.is_default?)
          list.option(value: activity.id, label: activity.name, selected:)
        end
      end

      f.text_area name: :comments, label: TimeEntry.human_attribute_name(:comments)

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

    def show_user_field?
      # Only allow setting a different user, when the user has the
      # permission to log time for others in the project
      User.current.allowed_in_project?(:log_time, project)
    end

    def show_start_and_end_time_fields?
      TimeEntry.can_track_start_and_end_time?
    end

    def activities
      TimeEntryActivity.active_in_project(project)
    end
  end
end
