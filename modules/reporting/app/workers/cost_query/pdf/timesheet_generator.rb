class CostQuery::PDF::TimesheetGenerator
  include WorkPackage::PDFExport::Common::Common
  include WorkPackage::PDFExport::Export::Cover
  include WorkPackage::PDFExport::Common::Logo
  include WorkPackage::PDFExport::Export::Page
  include WorkPackage::PDFExport::Export::Style

  attr_accessor :pdf

  def initialize(query, project, cost_types)
    @query = query
    @project = project
    @cost_types = cost_types
    setup_page!
  end

  def heading
    query.name || I18n.t(:"export.timesheet.timesheet")
  end

  def footer_title
    heading
  end

  def project
    @project
  end

  def query
    @query
  end

  def options
    {}
  end

  def setup_page!
    self.pdf = get_pdf
    @page_count = 0
    configure_page_size!(:portrait)
    pdf.title = heading
  end

  def generate!
    render_doc
    pdf.render
  rescue StandardError => e
    Rails.logger.error { "Failed to generate PDF: #{e} #{e.message}}." }
    error(I18n.t(:error_pdf_failed_to_export, error: e.message))
  end

  def render_doc
    write_cover_page! if with_cover?
    write_heading!
    write_hr!
    write_entries!
    write_headers!
    write_footers!
  end

  def write_entries!
    all_entries
      .group_by { |r| r.fields["user_id"] }
      .each do |user_id, result|
      write_table(user_id, result)
    end
  end

  def all_entries
    query
      .each_direct_result
      .map(&:itself)
      .filter { |r| r.fields["type"] == "TimeEntry" }
  end

  # rubocop:disable Metrics/AbcSize
  def build_table_rows(entries)
    rows = []
    entries
      .group_by { |r| DateTime.parse(r.fields["spent_on"]) }
      .sort
      .each do |spent_on, lines|
      day_rows = []
      lines.each do |r|
        day_rows.push(
          [
            wp_subject(r.fields["work_package_id"]),
            with_times_column? ? "??:00-??:00" : nil,
            format_duration(r.fields["units"]),
            activity_name(r.fields["activity_id"])
          ].compact
        )
        if r.fields["comments"].present?
          day_rows.push ([{ content: r.fields["comments"], text_color: "636C76", colspan: table_columns_span }])
        end
      end
      day_rows[0].unshift({ content: format_date(spent_on), rowspan: day_rows.length })
      rows.concat(day_rows)
    end
    rows
  end

  # rubocop:enable Metrics/AbcSize

  def table_header_columns
    [
      I18n.t(:"activerecord.attributes.time_entry.spent_on"),
      I18n.t(:"activerecord.models.work_package"),
      with_times_column? ? I18n.t(:"export.timesheet.time") : nil,
      I18n.t(:"activerecord.attributes.time_entry.hours"),
      I18n.t(:"activerecord.attributes.time_entry.activity")
    ].compact
  end

  def table_columns_widths
    with_times_column? ? [80, 193, 80, 70, 100] : [80, 270, 70, 100]
  end

  def table_width
    table_columns_widths.sum
  end

  def table_columns_span
    with_times_column? ? 4 : 3
  end

  # rubocop:disable Metrics/AbcSize
  def write_table(user_id, entries)
    rows = [table_header_columns].concat(build_table_rows(entries))
    # TODO: write user on new page if table does not fit on the same
    write_user(user_id)
    pdf.make_table(
      rows,
      header: false,
      width: table_width,
      column_widths: table_columns_widths,
      cell_style: {
        border_color: "BBBBBB",
        border_width: 0.5,
        borders: %i[top bottom],
        padding: [5, 5, 8, 5]
      }
    ) do |table|
      table.columns(0).borders = %i[top bottom left right]
      table.columns(-1).style do |c|
        c.borders = c.borders + [:right]
      end
      table.columns(1).style do |c|
        if c.colspan > 1
          c.borders = %i[left right bottom]
          c.padding = [0, 5, 8, 5]
          row_nr = c.row - 1
          values = table.columns(1..-1).rows(row_nr..row_nr)
          values.each do |cell|
            cell.borders = cell.borders - [:bottom]
          end
        end
      end
      table.rows(0).style do |c|
        c.borders = c.borders + [:top]
        c.font_style = :bold
      end
    end.draw
  end

  # rubocop:enable Metrics/AbcSize

  def sorted_results
    query.each_direct_result.map(&:itself)
  end

  # rubocop:disable Metrics/AbcSize
  def write_hr!
    hr_style = styles.cover_header_border
    pdf.stroke do
      pdf.line_width = hr_style[:height]
      pdf.stroke_color hr_style[:color]
      pdf.stroke_horizontal_line pdf.bounds.left, pdf.bounds.right, at: pdf.cursor
    end
    pdf.move_down(16)
  end

  # rubocop:enable Metrics/AbcSize

  def write_heading!
    pdf.formatted_text([{ text: heading, size: 26, style: :bold }])
    pdf.move_down(2)
  end

  def write_user(user_id)
    pdf.formatted_text([{ text: user_name(user_id), size: 20 }])
    pdf.move_down(10)
  end

  def user_name(user_id)
    User.select_for_name.find(user_id).name
  end

  def activity_name(activity_id)
    TimeEntryActivity.find(activity_id).name
  end

  def wp_subject(wp_id)
    WorkPackage.find(wp_id).subject
  end

  def format_duration(hours)
    return "" if hours < 0

    "#{hours}h"
  end

  def with_times_column?
    true
  end

  def with_cover?
    false
  end
end
