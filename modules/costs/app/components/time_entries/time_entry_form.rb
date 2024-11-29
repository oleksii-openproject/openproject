module TimeEntries
  class TimeEntryForm < ApplicationForm
    include CustomFields::CustomFieldRendering

    form do |f|
      if show_user_field?
        f.text_field name: :user_id, label: "User"
      end
      f.text_field name: :spent_on, label: "Date"
      f.group(layout: :horizontal) do |g|
        g.text_field name: :start_time, label: "Start time"
        g.text_field name: :end_time, label: "Finish time"
      end
      f.text_field name: :hours, label: "Hours"
      if show_work_package_field?
        f.text_field name: :work_package_id, label: "Work package"
      end
      f.text_field name: :activity, label: "Activity"
      f.text_field name: :comments, label: "Comments"

      render_custom_fields(form: f)
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
