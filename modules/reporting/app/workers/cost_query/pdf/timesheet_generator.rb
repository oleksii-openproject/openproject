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
    "Timesheet"
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

    pdf.formatted_text([{ text: heading }])
    write_hr
    query
      .each_direct_result
      .map(&:itself)
      .group_by { |r| r.fields["user_id"] }
      .each do |user_id, result|
      write_table(user_id, result)
    end
  end

  # rubocop:disable Metrics/AbcSize
  def build_table_rows(entries)
    rows = []
    entries
      .group_by { |r| DateTime.parse(r.fields["spent_on"]) }
      .sort
      .each do |_spent_on, lines|
      lines.each do |r|
        rows.push([
                    lines[0]["spent_on"],
                    WorkPackage.find(r.fields["work_package_id"]).subject,
                    "??:00-??:00",
                    "#{r.fields['units'].inspect}h",
                    TimeEntryActivity.find(r.fields["activity_id"]).name
                  ])
      end
    end
    rows
  end
  # rubocop:enable Metrics/AbcSize

  def write_table(user_id, entries)
    rows = [["Date", "Work package", "Time", "Hours", "Activity"]].concat(build_table_rows(entries))
    # TODO: write user on new page if table does not fit on the same
    write_user(user_id)
    table = pdf.make_table(rows, header: false, width: 500, column_widths: [100, 100, 100, 100, 100])
    table.draw
  end

  def write_user(user_id)
    pdf.formatted_text([{ text: User.select_for_name.find(user_id).name }])
  end

  def sorted_results
    query.each_direct_result.map(&:itself)
  end

  # rubocop:disable Metrics/AbcSize
  def write_hr
    hr_style = styles.cover_header_border
    pdf.stroke_color = hr_style[:color]
    pdf.line_width = hr_style[:height]
    pdf.stroke_horizontal_line pdf.bounds.left, pdf.bounds.right, at: pdf.cursor
  end
  # rubocop:enable Metrics/AbcSize

  def with_cover?
    true
  end
end
