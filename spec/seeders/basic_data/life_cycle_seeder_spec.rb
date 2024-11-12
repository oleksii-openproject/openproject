# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe BasicData::LifeCycleSeeder do
  subject(:seeder) { described_class.new(seed_data) }
  let(:initial_seed_data) { {} }
  let(:seed_data) { initial_seed_data.merge(Source::SeedData.new(data_hash)) }

  context "with some life cycles defined" do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        life_cycles:
        - reference: :default_life_cycle_initiating
          name: Initiating
          type: Stage
          color_name: :default_color_orange_dark
        - reference: :default_life_cycle_planning
          name: Planning
          type: Stage
          color_name: :default_color_red_dark
        - reference: :default_life_cycle_executing
          name: Executing
          type: Stage
          color_name: :default_color_magenta_light
        - reference: :default_life_cycle_closing
          name: Closing
          type: Stage
          color_name: :default_color_green_yellow
      SEEDING_DATA_YAML
    end

    shared_examples_for "creates the life_cycles seeds" do
      it "creates the corresponding life cycles with the given attributes" do
        expect(LifeCycle.count).to eq(4)
        expect(Stage.find_by(name: "Initiating")).to have_attributes(
          color_id: Color.find_by(name: "Orange (dark)").id
        )
        expect(Stage.find_by(name: "Planning")).to have_attributes(
          color_id: Color.find_by(name: "Red (dark)").id
        )
        expect(Stage.find_by(name: "Executing")).to have_attributes(
          color_id: Color.find_by(name: "Magenta (light)").id
        )
        expect(Stage.find_by(name: "Closing")).to have_attributes(
          color_id: Color.find_by(name: "Green Yellow").id
        )
      end

      it "references the life cycles in the seed data" do
        Stage.all.each do |expected_stage|
          reference = :"default_life_cycle_#{expected_stage.name.downcase}"
          expect(seed_data.find_reference(reference)).to eq(expected_stage)
        end
      end

      context "when seeding a second time" do
        subject(:second_seeder) { described_class.new(second_seed_data) }

        let(:second_seed_data) { initial_seed_data.merge(Source::SeedData.new(data_hash)) }

        before do
          second_seeder.seed!
        end

        it "registers existing matching life cycles as references in the seed data" do
          # using the first seed data as the expected value
          expect(second_seed_data.find_reference(:default_life_cycle_initiating))
            .to eq(seed_data.find_reference(:default_life_cycle_initiating))
          expect(second_seed_data.find_reference(:default_life_cycle_planning))
            .to eq(seed_data.find_reference(:default_life_cycle_planning))
          expect(second_seed_data.find_reference(:default_life_cycle_executing))
            .to eq(seed_data.find_reference(:default_life_cycle_executing))
          expect(second_seed_data.find_reference(:default_life_cycle_closing))
            .to eq(seed_data.find_reference(:default_life_cycle_closing))
        end
      end
    end

    context "and colors seeded" do
      include_context "with basic seed data"
      let(:initial_seed_data) { basic_seed_data }

      before do
        seeder.seed!
      end

      it_behaves_like "creates the life_cycles seeds"
    end
  end

  context "without life cycles defined" do
    include_context "with basic seed data"
    let(:initial_seed_data) { basic_seed_data }

    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        nothing here: ''
      SEEDING_DATA_YAML
    end

    before do
      seeder.seed!
    end

    it "creates no life cycles" do
      expect(LifeCycle.count).to eq(0)
    end
  end
end
