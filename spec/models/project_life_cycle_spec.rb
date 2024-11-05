require "rails_helper"

RSpec.describe ProjectLifeCycle do
  it { is_expected.to belong_to(:project).required(true) }
  it { is_expected.to belong_to(:life_cycle).required(true) }
end
