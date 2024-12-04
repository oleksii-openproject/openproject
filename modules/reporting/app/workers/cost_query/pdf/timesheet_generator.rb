class CostQuery::PDF::TimesheetGenerator
  include WorkPackage::PDFExport::Common::Common
  include WorkPackage::PDFExport::Export::Cover
  include WorkPackage::PDFExport::Common::Logo
  include WorkPackage::PDFExport::Export::Page
  include WorkPackage::PDFExport::Export::Style

  H1_FONT_SIZE = 26
  H1_MARGIN_BOTTOM = 2
  HR_MARGIN_BOTTOM = 16
  TABLE_CELL_FONT_SIZE = 10
  TABLE_CELL_BORDER_COLOR = "BBBBBB".freeze
  TABLE_CELL_PADDING = 4
  COMMENT_FONT_COLOR = "636C76".freeze
  H2_FONT_SIZE = 20
  H2_MARGIN_BOTTOM = 10
  COLUMN_DATE_WIDTH = 66
  COLUMN_ACTIVITY_WIDTH = 100
  COLUMN_HOURS_WIDTH = 60
  COLUMN_TIME_WIDTH = 100
  COLUMN_WP_WIDTH = 200

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
      .group_by(&:user)
      .each do |user, result|
      write_table(user, result)
    end
  end

  def all_entries
    query
      .each_direct_result
      .map(&:itself)
      .filter { |r| r.fields["type"] == "TimeEntry" }
      .map { |r| TimeEntry.find(r.fields["id"]) }
  end

  def build_table_rows(entries)
    rows = [table_header_columns]
    entries
      .group_by(&:spent_on)
      .sort
      .each do |spent_on, lines|
      rows.concat(build_table_day_rows(spent_on, lines))
    end
    rows
  end

  def build_table_day_rows(spent_on, entries)
    day_rows = []
    entries.each do |entry|
      day_rows.push(build_table_row(spent_on, entry))
      if entry.comments.present?
        day_rows.push(build_table_row_comment(entry))
      end
    end
    day_rows
  end

  def build_table_row(spent_on, entry)
    [
      { content: format_date(spent_on), rowspan: entry.comments.present? ? 2 : 1 },
      entry.work_package.subject || "",
      with_times_column? ? format_spent_on_time(entry) : nil,
      format_duration(entry.hours),
      entry.activity&.name || ""
    ].compact
  end

  def build_table_row_comment(entry)
    [{
      content: entry.comments,
      text_color: COMMENT_FONT_COLOR,
      font_style: :italic,
      colspan: table_columns_widths.size
    }]
  end

  def table_header_columns
    [
      { content: I18n.t(:"activerecord.attributes.time_entry.spent_on"), rowspan: 1 },
      I18n.t(:"activerecord.models.work_package"),
      with_times_column? ? I18n.t(:"export.timesheet.time") : nil,
      I18n.t(:"activerecord.attributes.time_entry.hours"),
      I18n.t(:"activerecord.attributes.time_entry.activity")
    ].compact
  end

  def table_columns_widths
    @table_columns_widths ||= if with_times_column?
                                [COLUMN_DATE_WIDTH, COLUMN_WP_WIDTH, COLUMN_TIME_WIDTH, COLUMN_HOURS_WIDTH,
                                 COLUMN_ACTIVITY_WIDTH]
                              else
                                [COLUMN_DATE_WIDTH, COLUMN_WP_WIDTH + COLUMN_TIME_WIDTH, COLUMN_HOURS_WIDTH,
                                 COLUMN_ACTIVITY_WIDTH]
                              end
  end

  def build_table(rows)
    pdf.make_table(
      rows,
      header: true,
      width: table_columns_widths.sum,
      column_widths: table_columns_widths,
      cell_style: {
        size: TABLE_CELL_FONT_SIZE,
        border_color: TABLE_CELL_BORDER_COLOR,
        border_width: 0.5,
        borders: %i[top bottom],
        padding: [TABLE_CELL_PADDING, TABLE_CELL_PADDING, TABLE_CELL_PADDING + 2, TABLE_CELL_PADDING]
      }
    ) do |table|
      adjust_borders_first_column(table)
      adjust_borders_last_column(table)
      adjust_borders_spanned_column(table)
      adjust_border_header_row(table)
    end
  end

  def adjust_borders_first_column(table)
    table.columns(0).borders = %i[top bottom left right]
  end

  def adjust_borders_last_column(table)
    table.columns(0).borders = %i[top bottom left right]
  end

  def adjust_borders_spanned_column(table)
    table.columns(1).style do |c|
      if c.colspan > 1
        c.borders = %i[left right bottom]
        c.padding = [0, TABLE_CELL_PADDING, TABLE_CELL_PADDING + 2, TABLE_CELL_PADDING]
        row_nr = c.row - 1
        values = table.columns(1..-1).rows(row_nr..row_nr)
        values.each do |cell|
          cell.borders = cell.borders - [:bottom]
        end
      end
    end
  end

  def adjust_border_header_row(table)
    table.rows(0).style do |c|
      c.borders = c.borders + [:top]
      c.font_style = :bold
    end
  end

  def split_group_rows(table_rows)
    measure_table = build_table(table_rows)
    groups = []
    index = 0
    while index < table_rows.length
      row = table_rows[index]
      rows = [row]
      height = measure_table.row(index).height
      index += 1
      if (row[0][:rowspan] || 1) > 1
        rows.push(table_rows[index])
        height += measure_table.row(index).height
        index += 1
      end
      groups.push({ rows:, height: })
    end
    groups
  end

  def write_table(user, entries)
    rows = build_table_rows(entries)
    # prawn-table does not support splitting a rowspan cell on page break, so we have to merge the first column manually
    # for easier handling existing rowspan cells are grouped as one row
    grouped_rows = split_group_rows(rows)
    # start a new page if the username would be printed alone at the end of the page
    pdf.start_new_page if available_space_from_bottom < grouped_rows[0][:height] + grouped_rows[1][:height] + username_height
    write_username(user)
    write_grouped_tables(grouped_rows)
  end

  def available_space_from_bottom
    margin_bottom = pdf.options[:bottom_margin] + 20 # 20 is the safety margin
    pdf.y - margin_bottom
  end

  def write_grouped_tables(grouped_rows)
    header_row = grouped_rows[0]
    current_table = []
    current_table_height = 0
    grouped_rows.each do |grouped_row|
      grouped_row_height = grouped_row[:height]
      if current_table_height + grouped_row_height >= available_space_from_bottom
        write_grouped_row_table(current_table)
        pdf.start_new_page
        current_table = [header_row]
        current_table_height = header_row[:height]
      end
      current_table.push(grouped_row)
      current_table_height += grouped_row_height
    end
    write_grouped_row_table(current_table)
    pdf.move_down(28)
  end

  def write_grouped_row_table(grouped_rows)
    current_table = []
    merge_first_columns(grouped_rows)
    grouped_rows.map! { |row| current_table.concat(row[:rows]) }
    build_table(current_table).draw
  end

  def merge_first_columns(grouped_rows)
    last_row = grouped_rows[1]
    index = 2
    while index < grouped_rows.length
      grouped_row = grouped_rows[index]
      last_row = merge_first_rows(grouped_row, last_row)
      index += 1
    end
  end

  def merge_first_rows(grouped_row, last_row)
    grouped_cell = grouped_row[:rows][0][0]
    last_cell = last_row[:rows][0][0]
    if grouped_cell[:content] == last_cell[:content]
      last_cell[:rowspan] += grouped_cell[:rowspan]
      grouped_row[:rows][0].shift
      last_row
    else
      grouped_row
    end
  end

  def sorted_results
    query.each_direct_result.map(&:itself)
  end

  def write_hr!
    hr_style = styles.cover_header_border
    write_horizontal_line(pdf.cursor, hr_style[:height], hr_style[:color])
    pdf.move_down(HR_MARGIN_BOTTOM)
  end

  def write_heading!
    pdf.formatted_text([{ text: heading, size: H1_FONT_SIZE, style: :bold }])
    pdf.move_down(H1_MARGIN_BOTTOM)
  end

  def username_height
    20 + 10
  end

  def write_username(user)
    pdf.formatted_text([{ text: user.name, size: H2_FONT_SIZE }])
    pdf.move_down(H2_MARGIN_BOTTOM)
  end

  def format_duration(hours)
    return "" if hours < 0

    ::OpenProject::Common::DurationComponent.new(hours.to_f, :hours, abbreviated: true).text
  end

  def format_spent_on_time(entry)
    start_timestamp = entry.start_timestamp
    return "" if start_timestamp.nil?

    result = format_time(start_timestamp, include_date: false)
    end_timestamp = entry.end_timestamp
    return result if end_timestamp.nil?

    "#{result} - #{format_time(end_timestamp, include_date: false)}"
  end

  def with_times_column?
    Setting.allow_tracking_start_and_end_times
  end

  def with_cover?
    true
  end
end
