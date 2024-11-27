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

class WorkPackages::AutomaticMode::MigrateValuesJob < ApplicationJob
  def perform
    with_temporary_table do
      change_scheduling_mode_to_manual
      change_scheduling_mode_to_automatic_for_followers
      change_scheduling_mode_to_automatic_for_parents
      set_lags_for_follows_relations
      copy_values_to_work_packages_and_update_journals
    end
  end

  private

  def with_temporary_table
    WorkPackage.transaction do
      create_temporary_table
      yield
    ensure
      drop_temporary_table
    end
  end

  def create_temporary_table
    execute(<<~SQL.squish)
      CREATE UNLOGGED TABLE temp_wp_values
      AS SELECT
        id,
        start_date,
        due_date,
        schedule_manually
      FROM work_packages
    SQL
  end

  def drop_temporary_table
    execute(<<~SQL.squish)
      DROP TABLE temp_wp_values
    SQL
  end

  def change_scheduling_mode_to_manual
    execute(<<~SQL.squish)
      UPDATE temp_wp_values
      SET schedule_manually = true
    SQL
  end

  def change_scheduling_mode_to_automatic_for_followers
    execute(<<~SQL.squish)
      UPDATE temp_wp_values
      SET schedule_manually = false
      WHERE EXISTS (
        SELECT 1
        FROM relations
        WHERE relations.from_id = temp_wp_values.id
          AND relations.relation_type = 'follows'
      )
    SQL
  end

  def change_scheduling_mode_to_automatic_for_parents
    execute(<<~SQL.squish)
      UPDATE temp_wp_values
      SET schedule_manually = false
      WHERE id IN (
        SELECT DISTINCT parent_id
        FROM work_packages
        WHERE parent_id IS NOT NULL
      )
    SQL
  end

  def set_lags_for_follows_relations
    working_days = Setting.working_days

    # Here is the algorithm:
    # - Take all follows relations with dates
    # - Generate a series of dates between the min date and the max date and
    #   filter for working days
    # - Use both information to count the number of working days between
    #   predecessor and successor dates and update the lag with it
    execute(<<~SQL.squish)
      WITH follows_relations_with_dates AS (
        SELECT
          relations.id as id,
          COALESCE(wp_pred.due_date, wp_pred.start_date) as pred_date,
          COALESCE(wp_succ.start_date, wp_succ.due_date) as succ_date
        FROM relations
        LEFT JOIN work_packages wp_pred ON relations.to_id = wp_pred.id
        LEFT JOIN work_packages wp_succ ON relations.from_id = wp_succ.id
        WHERE relation_type = 'follows'
          AND COALESCE(wp_pred.due_date, wp_pred.start_date) IS NOT NULL
          AND COALESCE(wp_succ.start_date, wp_succ.due_date) IS NOT NULL
      ),
      working_dates AS (
        SELECT date::date
        FROM generate_series(
          (SELECT MIN(pred_date) FROM follows_relations_with_dates),
          (SELECT MAX(succ_date) FROM follows_relations_with_dates),
          '1 day'::interval
        ) AS date
        WHERE EXTRACT(ISODOW FROM date)::integer IN (#{working_days.join(',')})
          AND NOT date IN (SELECT date FROM non_working_days)
      )
      UPDATE relations
      SET lag = (
        SELECT COUNT(*)
        FROM working_dates
        WHERE date > pred_date
          AND date < succ_date
      )
      FROM follows_relations_with_dates
      WHERE relations.id = follows_relations_with_dates.id
    SQL
  end

  def copy_values_to_work_packages_and_update_journals
    updated_work_package_ids = copy_values_to_work_packages
    create_journals_for_updated_work_packages(updated_work_package_ids)
  end

  def copy_values_to_work_packages
    results = execute(<<~SQL.squish)
      UPDATE work_packages
      SET schedule_manually = temp_wp_values.schedule_manually,
          lock_version = lock_version + 1,
          updated_at = NOW()
      FROM temp_wp_values
      WHERE work_packages.id = temp_wp_values.id
        AND work_packages.schedule_manually IS DISTINCT FROM temp_wp_values.schedule_manually
      RETURNING work_packages.id
    SQL
    results.column_values(0)
  end

  def create_journals_for_updated_work_packages(updated_work_package_ids)
    cause = { type: "system_update", feature: "scheduling_mode_adjusted" }
    WorkPackage.where(id: updated_work_package_ids).find_each do |work_package|
      Journals::CreateService
        .new(work_package, system_user)
        .call(cause:)
    end
  end

  # Executes an sql statement, shorter.
  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end

  def system_user
    @system_user ||= User.system
  end
end
