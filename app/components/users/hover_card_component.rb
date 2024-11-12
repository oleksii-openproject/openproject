# frozen_string_literal: true

class Users::HoverCardComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(id:)
    super

    @id = id
    @user = User.find(@id)
  end

  def show_email?
    (@user == User.current) || User.current.allowed_globally?(:view_user_email)
  end

  # Constructs a string in the form of:
  # "Member of project4, project5"
  # or
  # "Member of project1, project2 and 3 more"
  # The latter string is cut off since the complete list of project names would exceed the allowed `max_length`.
  def project_membership_summary(max_length = 50)
    project_names = @user.projects.pluck(:name)
    return no_project_text if project_names.empty?

    cutoff_index = calculate_cutoff_index(project_names, max_length)
    build_summary(project_names, cutoff_index)
  end

  private

  def no_project_text
    t("users.memberships.no_results_title_text")
  end

  def calculate_cutoff_index(names, max_length)
    current_length = 0

    names.each_with_index do |name, index|
      new_length = current_length + name.length + (index > 0 ? 2 : 0) # 2 for ", " separator
      return index if new_length > max_length

      current_length = new_length
    end

    names.size # No cutoff needed -> return the total size
  end

  def build_summary(names, cutoff_index)
    summary_names = names[0...cutoff_index].join(", ")
    remaining_count = names.size - cutoff_index

    if remaining_count > 0
      t("users.memberships.summary_with_more", names: summary_names, count: remaining_count)
    else
      t("users.memberships.summary", names: summary_names)
    end
  end
end
