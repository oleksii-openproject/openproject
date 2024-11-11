# frozen_string_literal: true

class Users::HoverCardComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(id:)
    super

    @id = id
    @user = User.find(@id)
  end

  def show_email?
    false
  end
end
