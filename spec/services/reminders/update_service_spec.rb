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
require "services/base_services/behaves_like_update_service"

RSpec.describe Reminders::UpdateService do
  it_behaves_like "BaseServices update service" do
    let(:factory) { :reminder }
  end

  describe "remind_at changed" do
    subject { described_class.new(user:, model: model_instance).call(call_attributes) }

    let(:model_instance) { create(:reminder, :scheduled, creator: user, job_id: 1) }
    let(:user) { create(:admin) }
    let(:call_attributes) { { remind_at: 2.days.from_now } }

    before do
      allow(Reminders::ScheduleReminderJob).to receive(:schedule)
        .with(model_instance)
        .and_return(instance_double(Reminders::ScheduleReminderJob, job_id: 2))
    end

    context "with an existing unfinished scheduled job" do
      let(:job) { instance_double(GoodJob::Job, finished?: false, destroy: true) }

      before do
        allow(GoodJob::Job).to receive(:find_by).with(id: "1").and_return(job)
      end

      it "reschedules the reminder" do
        expect { subject }.to change(model_instance, :job_id).from("1").to("2")

        aggregate_failures "destroy existing job" do
          expect(GoodJob::Job).to have_received(:find_by).with(id: "1")
          expect(job).to have_received(:destroy)
        end

        aggregate_failures "schedule new job" do
          expect(Reminders::ScheduleReminderJob).to have_received(:schedule).with(model_instance)
        end
      end
    end

    context "with an existing finished scheduled job" do
      let(:job) { instance_double(GoodJob::Job, finished?: true, destroy: true) }

      before do
        allow(GoodJob::Job).to receive(:find_by).with(id: "1").and_return(job)
      end

      it "schedules a new job" do
        expect { subject }.to change(model_instance, :job_id).from("1").to("2")

        aggregate_failures "does NOT destroy existing job" do
          expect(GoodJob::Job).to have_received(:find_by).with(id: "1")
          expect(job).not_to have_received(:destroy)
        end

        aggregate_failures "schedule new job" do
          expect(Reminders::ScheduleReminderJob).to have_received(:schedule).with(model_instance)
        end
      end
    end

    context "with remind_at attribute in non-utc timezone" do
      let(:call_attributes) { { remind_at: 2.days.from_now.in_time_zone("Africa/Nairobi") } }

      it "schedules the reminder" do
        expect { subject }.to change(model_instance, :job_id).from("1").to("2")
      end
    end
  end
end
