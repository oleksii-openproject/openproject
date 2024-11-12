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
  def project_membership_summary(max_length = 40)
    projects = @user.projects
    project_links = linked_project_names(projects)
    return no_project_text if project_links.empty?

    cutoff_index = calculate_cutoff_index(projects.map(&:name), max_length)
    build_summary(project_links, cutoff_index)
  end

  private

  def linked_project_names(projects)
    projects.map { |project| link_to(h(project.name), project_path(project)) }
  end

  def no_project_text
    t("users.memberships.no_results_title_text")
  end

  # Calculate the index at which to cut off the project names, based on plain text length
  def calculate_cutoff_index(names, max_length)
    current_length = 0

    names.each_with_index do |name, index|
      new_length = current_length + name.length + (index > 0 ? 2 : 0) # 2 for ", " separator
      return index if new_length > max_length

      current_length = new_length
    end

    names.size # No cutoff needed -> return the total size
  end

  def build_summary(links, cutoff_index)
    summary_links = safe_join(links[0...cutoff_index], ", ")
    remaining_count = links.size - cutoff_index

    if remaining_count > 0
      t("users.memberships.summary_with_more", names: summary_links, count: remaining_count).html_safe
    else
      t("users.memberships.summary", names: summary_links).html_safe
    end
  end
end
