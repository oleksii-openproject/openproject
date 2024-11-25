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

RSpec.describe Reminder do
  describe "Associations" do
    it { is_expected.to belong_to(:remindable) }
    it { is_expected.to belong_to(:creator).class_name("User") }
    it { is_expected.to belong_to(:notification).optional }
  end

  describe "DB Indexes" do
    it { is_expected.to have_db_index(:notification_id).unique(true) }
  end

  describe "#notified?" do
    it "returns true if notification_id is present" do
      reminder = build_stubbed(:reminder, :notified)

      expect(reminder).to be_notified
    end

    it "returns false if notification_id is not present" do
      reminder = build(:reminder, notification_id: nil)

      expect(reminder).not_to be_notified
    end
  end

  describe "#scheduled?" do
    it "returns true if job_id is present" do
      reminder = build_stubbed(:reminder, :scheduled)

      expect(reminder).to be_scheduled
    end

    it "returns false if job_id is not present" do
      reminder = build(:reminder, job_id: nil)

      expect(reminder).not_to be_scheduled
    end
  end
end
