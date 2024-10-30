class WorkPackageRelationsTab::RelationComponent < ApplicationComponent
  include ApplicationHelper
  include OpPrimer::ComponentHelpers

  attr_reader :work_package, :relation

  def initialize(work_package:,
                 relation:,
                 child: nil)
    super()

    @work_package = work_package
    @relation = relation
    @child = child
  end

  def related_work_package
    @related_work_package ||= if parent_child_relationship?
                                @child
                              else
                                relation.from == work_package ? relation.to : relation.from
                              end
  end

  private

  def parent_child_relationship? = @child.present?

  def underlying_resource_id
    @underlying_resource_id ||= if parent_child_relationship?
                                  @child.id
                                else
                                  @relation.id
                                end
  end

  def destroy_path
    if parent_child_relationship?
      work_package_child_path(@child)
    else
      work_package_relation_path(@work_package, @relation)
    end
  end

  def action_menu_test_selector
    "op-relation-row-#{underlying_resource_id}-action-menu"
  end

  def delete_button_test_selector
    "op-relation-row-#{underlying_resource_id}-delete-button"
  end
end
