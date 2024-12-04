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
require_module_spec_helper

RSpec.describe RecurringMeetings::InitNextOccurrenceJob, type: :model do
  shared_let(:series) do
    create(:recurring_meeting,
           start_time: Time.zone.tomorrow + 10.hours,
           frequency: "daily",
           interval: 1,
           end_after: "specific_date",
           end_date: 1.month.from_now)
  end

  subject { described_class.perform_now(series) }

  it "schedules the next occurrence" do
    expect { subject }.to change(StructuredMeeting, :count).by(1)
    expect(subject).to be_success

    created_meeting = subject.result
    expect(created_meeting.start_time).to eq(Time.zone.tomorrow + 10.hours)
  end

  context "when next occurrence is cancelled" do
    let!(:schedule) do
      create(:scheduled_meeting,
             :cancelled,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 10.hours)
    end

    it "does not schedule anything" do
      expect { subject }.not_to change(StructuredMeeting, :count)
      expect(subject).to be_nil
    end
  end

  context "when next occurrence is already instantiated" do
    let!(:instance) do
      create(:structured_meeting,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 10.hours)
    end

    let!(:schedule) do
      create(:scheduled_meeting,
             meeting: instance,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 10.hours)
    end

    it "does not schedule anything" do
      expect { subject }.not_to change(StructuredMeeting, :count)
      expect(subject).to be_nil
    end
  end

  context "when next occurrence is already instantiated, and moved" do
    let!(:instance) do
      create(:structured_meeting,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 1.day + 10.hours)
    end

    let!(:schedule) do
      create(:scheduled_meeting,
             meeting: instance,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 10.hours)
    end

    it "does not schedule anything" do
      expect { subject }.not_to change(StructuredMeeting, :count)
      expect(subject).to be_nil
    end
  end

  context "when later occurrence is already instantiated" do
    let!(:instance) do
      create(:structured_meeting,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 1.day + 10.hours)
    end

    let!(:schedule) do
      create(:scheduled_meeting,
             meeting: instance,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 1.day + 10.hours)
    end

    it "schedules the one for tomorrow" do
      expect { subject }.to change(StructuredMeeting, :count).by(1)
      expect(subject).to be_success

      created_meeting = subject.result
      expect(created_meeting.start_time).to eq(Time.zone.tomorrow + 10.hours)
    end
  end

  context "when called after end_date" do
    it "does not schedule the next occurrence" do
      Timecop.freeze(series.end_date + 1.day) do
        expect { subject }.not_to change(StructuredMeeting, :count)
        expect(subject).to be_nil
      end
    end
  end

  context "when called on last occurrence" do
    it "does not schedule the next occurrence" do
      Timecop.freeze(series.last_occurrence) do
        expect { subject }.not_to change(StructuredMeeting, :count)
        expect(subject).to be_nil
      end
    end
  end
end
