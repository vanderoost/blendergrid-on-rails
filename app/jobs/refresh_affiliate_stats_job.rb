# TODO: Take refunds into account
class RefreshAffiliateStatsJob < ApplicationJob
  queue_as :default

  def perform
    year = Date.yesterday.year
    month = Date.yesterday.month

    Affiliate.all.each do |affiliate|
      date_range = Date.new(year, month, 1)..Date.new(year, month, -1)
      page_variant_ids = affiliate.landing_page.page_variant_ids

      stats = {
        visits: calculate_visits(page_variant_ids, date_range),
        signups: calculate_signups(page_variant_ids, date_range),
        sales_cents: calculate_sales(
          page_variant_ids,
          date_range,
          affiliate.reward_window_months
        ),
      }

      stats[:rewards_cents] = (
        stats[:sales_cents] * affiliate.reward_percent.fdiv(100)
      ).round

      AffiliateMonthlyStat.upsert({
        affiliate_id: affiliate.id,
        year: year,
        month: month,
        **stats,
      }, unique_by: [ :affiliate_id, :year, :month ])
    end
  end

  private
    def calculate_visits(page_variant_ids, date_range)
      Request.joins(:events)
        .where(
          events: {
            resource_type: "PageVariant",
            resource_id: page_variant_ids,
            action: :showed,
          },
          created_at: date_range
        )
        .distinct
        .count(:visitor_id)
    end

    def calculate_signups(page_variant_ids, date_range)
      User.where(
        page_variant_id: page_variant_ids,
        created_at: date_range
      ).count
    end

    def calculate_sales(page_variant_ids, date_range, reward_window_months)
      attributed_users = User.where(page_variant_id: page_variant_ids)

      total_sales = 0

      attributed_users.find_each do |user|
        reward_end_date = user.created_at + reward_window_months.months
        sale_date_range = [ date_range.begin, user.created_at ].max..
                          [ date_range.end, reward_end_date ].min

        next if sale_date_range.begin > sale_date_range.end

        orders_total = user.orders
          .where(created_at: sale_date_range)
          .sum(:cash_cents)

        topups_total = user.credit_entries
          .where(reason: :topup, created_at: sale_date_range)
          .sum(:amount_cents)

        total_sales += orders_total + topups_total
      end

      total_sales
    end
end
