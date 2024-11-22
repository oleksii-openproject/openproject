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
    it { is_expected.to have_many(:reminder_notifications).dependent(:destroy) }
  end

  describe "#notified?" do
    context "when notified_at is present" do
      subject { build(:reminder, :notified) }

      it { is_expected.to be_notified }
    end

    context "when notified_at is not present" do
      subject { build(:reminder) }

      it { is_expected.not_to be_notified }
    end
  end

  describe "#scheduled?" do
    context "when job_id is present" do
      subject { build(:reminder, :scheduled) }

      it { is_expected.to be_scheduled }
    end

    context "when job_id is not present" do
      subject { build(:reminder) }

      it { is_expected.not_to be_scheduled }
    end
  end
end
