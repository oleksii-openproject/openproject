# frozen_string_literal: true

module OpenProject::Users
  # @logical_path OpenProject/Users
  class AvatarComponentPreview < Lookbook::Preview
    # Renders a user avatar using the OpenProject opce-principal web component. Note that the hover card options
    # have no effect in this lookbook.
    # @param size select { choices: [default, medium, mini] }
    # @param link toggle
    # @param show_name toggle
    # @param hover_card toggle
    # @param hover_card_target select { choices: [default, custom] }
    def default(size: :default, link: true, show_name: true, hover_card: true, hover_card_target: :default)
      user = FactoryBot.build_stubbed(:user)
      render(Users::AvatarComponent.new(user:, size:, link:, show_name:,
                                        hover_card: { active: hover_card, target: hover_card_target }))
    end

    def sizes
      user = FactoryBot.build_stubbed(:user)
      render_with_template(locals: { user: })
    end
  end
end
