# frozen_string_literal: true

class WorkPackageRelationsTab::IndexComponent < ApplicationComponent
  FRAME_ID = "work-package-relations-tab-content"
  NEW_RELATION_ACTION_MENU = "new-relation-action-menu"
  I18N_NAMESPACE = "work_package_relations_tab"
  include ApplicationHelper
  include OpPrimer::ComponentHelpers
  include Turbo::FramesHelper
  include OpTurbo::Streamable

  attr_reader :work_package, :relations, :children, :directionally_aware_grouped_relations

  def initialize(work_package:, relations:, children:)
    super()

    @work_package = work_package
    @relations = relations
    @children = children
    @directionally_aware_grouped_relations = group_relations_by_directional_context
  end

  def self.wrapper_key
    FRAME_ID
  end

  private

  def group_relations_by_directional_context
    relations.group_by do |relation|
      target = relation.to == work_package ? "from" : "to"
      target == "from" ? relation.reverse_type : relation.relation_type
    end
  end

  def any_relations? = relations.any? || children.any?

  def render_relation_group(title:, items:, &_block)
    render(border_box_container(padding: :condensed)) do |border_box|
      border_box.with_header(py: 3) do
        flex_layout(align_items: :center) do |flex|
          flex.with_column(mr: 2) do
            render(Primer::Beta::Text.new(font_size: :normal, font_weight: :bold)) { title }
          end
          flex.with_column do
            render(Primer::Beta::Counter.new(count: items.size, round: true, scheme: :primary))
          end
        end
      end

      items.each do |item|
        border_box.with_row(py: 2, test_selector: row_test_selector(item)) do
          yield(item)
        end
      end
    end
  end

  def new_relation_path(relation_type:)
    raise ArgumentError, "Invalid relation type: #{relation_type}" unless Relation::TYPES.key?(relation_type)

    if relation_type == Relation::TYPE_CHILD
      raise NotImplementedError, "Child relations are not supported yet"
    else
      new_work_package_relation_path(work_package, relation_type:)
    end
  end

  def new_button_test_selector(relation_type:)
    "op-new-relation-button-#{relation_type}"
  end

  def row_test_selector(item)
    "op-relation-row-#{item.id}"
  end
end
