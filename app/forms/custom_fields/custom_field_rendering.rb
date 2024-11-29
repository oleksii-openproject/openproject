module CustomFields::CustomFieldRendering
  include ActiveSupport::Concern

  def render_custom_fields(form:)
    custom_fields.each do |custom_field|
      form.fields_for(:custom_field_values) do |builder|
        custom_field_input(builder, custom_field)
      end
    end
  end

  # override if you want to pass more attributes
  def additional_custom_field_input_arguments
    {}
  end

  def custom_fields
    raise NotImplementedError, "#custom_fields method needs to be overwritten and provide all custom fields we want to show"
  end

  private

  def custom_field_input(builder, custom_field)
    if custom_field.multi_value?
      multi_value_custom_field_input(builder, custom_field)
    else
      single_value_custom_field_input(builder, custom_field)
    end
  end

  def form_arguments(custom_field)
    {
      custom_field: custom_field,
      object: model,
      wrapper_id: @wrapper_id
    }.merge(additional_custom_field_input_arguments)
  end

  # TBD: transform inputs called below to primer form dsl instead of form classes?
  # TODOS:
  # - initial values for user inputs are not displayed
  # - allow/disallow-non-open version setting is not yet respected in the version selector
  # - rich text editor is not yet supported

  def single_value_custom_field_input(builder, custom_field)
    form_args = form_arguments(custom_field)

    case custom_field.field_format
    when "string", "link"
      CustomFields::Inputs::String.new(builder, **form_args)
    when "text"
      CustomFields::Inputs::Text.new(builder, **form_args)
    when "int"
      CustomFields::Inputs::Int.new(builder, **form_args)
    when "float"
      CustomFields::Inputs::Float.new(builder, **form_args)
    when "list"
      CustomFields::Inputs::SingleSelectList.new(builder, **form_args)
    when "date"
      CustomFields::Inputs::Date.new(builder, **form_args)
    when "bool"
      CustomFields::Inputs::Bool.new(builder, **form_args)
    when "user"
      CustomFields::Inputs::SingleUserSelectList.new(builder, **form_args)
    when "version"
      CustomFields::Inputs::SingleVersionSelectList.new(builder, **form_args)
    end
  end

  def multi_value_custom_field_input(builder, custom_field)
    form_args = form_arguments(custom_field)

    case custom_field.field_format
    when "list"
      CustomFields::Inputs::MultiSelectList.new(builder, **form_args)
    when "user"
      CustomFields::Inputs::MultiUserSelectList.new(builder, **form_args)
    when "version"
      CustomFields::Inputs::MultiVersionSelectList.new(builder, **form_args)
    end
  end
end
