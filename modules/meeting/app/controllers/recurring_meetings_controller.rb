class RecurringMeetingsController < ApplicationController
  include Layout
  include PaginationHelper
  include OpTurbo::ComponentStream
  include OpTurbo::FlashStreamHelper
  include OpTurbo::DialogStreamHelper

  before_action :find_meeting, only: %i[show update details_dialog destroy edit init delete_scheduled]
  before_action :find_optional_project, only: %i[index show new create update details_dialog destroy edit delete_scheduled]
  before_action :authorize_global, only: %i[index new create]
  before_action :authorize, except: %i[index new create]
  before_action :get_scheduled_meeting, only: %i[delete_scheduled]

  before_action :convert_params, only: %i[create update]

  menu_item :meetings

  def index
    @recurring_meetings =
      if @project
        RecurringMeeting.visible.where(project_id: @project.id)
      else
        RecurringMeeting.visible
      end

    respond_to do |format|
      format.html do
        render :index, locals: { menu_name: project_or_global_menu }
      end
    end
  end

  def new
    @recurring_meeting = RecurringMeeting.new(project: @project)
  end

  def show # rubocop:disable Metrics/AbcSize
    @direction = params[:direction]
    if @direction == "past"
      max_count = @recurring_meeting.scheduled_instances(upcoming: false).count
      @count = [(params[:count].to_i + 5), max_count].min
      @meetings = @recurring_meeting
        .scheduled_instances(upcoming: false).limit(@count)
    else
      max_count = @recurring_meeting.remaining_occurrences.count
      @count = [(params[:count].to_i + 5), max_count].min
      @meetings = upcoming_meetings(count: @count)
    end

    respond_to do |format|
      format.html do
        render :show, locals: { menu_name: project_or_global_menu }
      end
    end
  end

  def init
    call = ::RecurringMeetings::InitOccurrenceService
      .new(user: current_user, recurring_meeting: @recurring_meeting)
      .call(start_time: DateTime.iso8601(params[:start_time]))

    if call.success?
      redirect_to project_meeting_path(call.result.project, call.result), status: :see_other
    else
      flash[:error] = call.message
      redirect_to action: :show, id: @recurring_meeting
    end
  end

  def details_dialog
    respond_with_dialog Meetings::Index::DialogComponent.new(
      meeting: @recurring_meeting,
      project: @recurring_meeting.project
    )
  end

  def create # rubocop:disable Metrics/AbcSize
    call = ::RecurringMeetings::CreateService
      .new(user: current_user)
      .call(@converted_params)

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_create).html_safe
      redirect_to polymorphic_path([@project, :meeting], { id: call.result.template.id }),
                  status: :see_other
    else
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: Meetings::Index::FormComponent.new(
              meeting: call.result,
              project: @project,
              copy_from: @copy_from
            ),
            status: :bad_request
          )

          respond_with_turbo_streams
        end
      end
    end
  end

  def edit
    redirect_to controller: "meetings", action: "show", id: @recurring_meeting.template, status: :see_other
  end

  def update
    call = ::RecurringMeetings::UpdateService
      .new(model: @recurring_meeting, user: current_user)
      .call(@converted_params)

    if call.success?
      redirect_back(fallback_location: recurring_meeting_path(call.result), status: :see_other, turbo: false)
    else
      respond_to do |format|
        format.turbo_stream do
          update_via_turbo_stream(
            component: Meetings::Index::FormComponent.new(
              meeting: call.result,
              project: @project
            ),
            status: :bad_request
          )

          respond_with_turbo_streams
        end
      end
    end
  end

  def destroy
    if @recurring_meeting.destroy
      flash[:notice] = I18n.t(:notice_successful_delete)
    else
      flash[:error] = I18n.t(:error_failed_to_delete_entry)
    end

    respond_to do |format|
      format.html do
        redirect_to polymorphic_path([@project, :meetings])
      end
    end
  end

  def delete_scheduled
    if @scheduled.update(cancelled: true)
      flash[:notice] = I18n.t(:notice_successful_cancel)
    else
      flash[:error] = I18n.t(:error_failed_to_delete_entry)
    end

    redirect_to polymorphic_path([@project, @recurring_meeting]), status: :see_other
  end

  private

  def upcoming_meetings(count:)
    meetings = @recurring_meeting
      .scheduled_instances(upcoming: true)
      .index_by(&:start_time)

    merged = @recurring_meeting
      .scheduled_occurrences(limit: count)
      .map do |start_time|
      meetings.delete(start_time) || scheduled_meeting(start_time)
    end

    # Ensure we keep any remaining future meetings that exceed the limit
    merged + meetings.values.sort_by(&:start_time)
  end

  def scheduled_meeting(start_time)
    ScheduledMeeting.new(start_time:, recurring_meeting: @recurring_meeting)
  end

  def get_scheduled_meeting
    @scheduled = @recurring_meeting.scheduled_meetings.find_or_initialize_by(start_time: params[:start_time])

    render_400 unless @scheduled.meeting_id.nil?
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_meeting
    @recurring_meeting = RecurringMeeting.visible.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def convert_params
    # We do some preprocessing of `meeting_params` that we will store in this
    # instance variable.
    @converted_params = recurring_meeting_params.to_h

    @converted_params[:project] = @project
    @converted_params[:duration] = @converted_params[:duration].to_hours if @converted_params[:duration].present?
  end

  def recurring_meeting_params
    params
      .require(:meeting)
      .permit(:title, :location, :start_time_hour, :duration, :start_date,
              :interval, :frequency, :end_after, :end_date, :iterations)
  end

  def find_copy_from_meeting
    copied_from_meeting_id = params[:copied_from_meeting_id] || params[:meeting][:copied_from_meeting_id]
    return unless copied_from_meeting_id

    @copy_from = Meeting.visible.find(copied_from_meeting_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def structured_meeting_params
    if params[:structured_meeting].present?
      params
        .require(:structured_meeting)
    end
  end
end
