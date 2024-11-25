require "active_storage/filename"

class CostQuery::PDF::ExportJob < Exports::ExportJob
  self.model = ::CostQuery

  def project
    options[:project]
  end

  def cost_types
    options[:cost_types]
  end

  def title
    I18n.t("export.timesheet.title")
  end

  private

  def export!
    handle_export_result(export, pdf_report_result)
  end

  def prepare!
    CostQuery::Cache.check
  end

  def pdf_report_result
    content = generate_timesheet
    time = Time.current.strftime("%Y-%m-%d-T-%H-%M-%S")
    export_title = "timesheet-#{time}.pdf"
    ::Exports::Result.new(format: :pdf,
                          title: export_title,
                          mime_type: "application/pdf",
                          content:)
  end

  def generate_timesheet
    self.query = CostQuery.new(project:)
    generator = ::CostQuery::PDF::TimesheetGenerator.new(query, project, cost_types)
    generator.generate!
  end
end
