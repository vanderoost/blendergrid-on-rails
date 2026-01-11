class RefreshAffiliateStatsJob < ApplicationJob
  queue_as :default

  def perform
    refresh_month(1.month.ago)
    refresh_month(Time.current)
  end

  def refresh_month(date)
    year = date.year
    month = date.month

    Affiliate.all.each do |affiliate|
      puts "Month: #{year}-#{month} - Affiliate: #{affiliate.user.name}"
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

      puts ""
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
                             .select(:id, :created_at, :email_address)
                             .to_a

      return 0 if attributed_users.empty?

      user_ids = attributed_users.map(&:id)

      # Calculate expanded date range to cover all possible reward windows
      max_user_creation = attributed_users.map(&:created_at).max
      expanded_end_date = [
        date_range.end,
        max_user_creation + reward_window_months.months,
      ].max
      expanded_date_range = date_range.begin..expanded_end_date

      # Fetch all potentially relevant orders in one query
      all_orders = Order.where(user_id: user_ids)
                        .where.not(stripe_payment_intent_id: nil)
                        .where(created_at: expanded_date_range)
                        .select(:id, :user_id, :cash_cents, :created_at)
                        .to_a

      # Fetch all refunds for these orders in one query
      order_ids = all_orders.map(&:id)
      refunds_by_order_id = {}
      if order_ids.any?
        Refund.joins(:order_item)
              .where(order_items: { order_id: order_ids })
              .group("order_items.order_id")
              .sum(:amount_cents)
              .each { |order_id, total| refunds_by_order_id[order_id] = total }
      end

      # Fetch all topups in one query
      all_topups = CreditEntry.where(
        user_id: user_ids,
        reason: :topup,
        created_at: expanded_date_range
      ).select(:user_id, :amount_cents, :created_at).to_a

      # Calculate sales per user
      total_sales = 0

      attributed_users.each do |user|
        reward_end_date = user.created_at + reward_window_months.months
        sale_date_range = [ date_range.begin, user.created_at ].max..
                          [ date_range.end, reward_end_date ].min

        next if sale_date_range.begin > sale_date_range.end

        # Filter orders for this user and date range (in memory)
        user_orders = all_orders.select do |order|
          order.user_id == user.id &&
          order.created_at >= sale_date_range.begin &&
          order.created_at <= sale_date_range.end
        end

        orders_total = user_orders.sum(&:cash_cents)
        refunds_total = user_orders.sum do |order|
          refunds_by_order_id[order.id] || 0
        end

        # Filter topups for this user and date range (in memory)
        topups_total = all_topups.select do |topup|
          topup.user_id == user.id &&
          topup.created_at >= sale_date_range.begin &&
          topup.created_at <= sale_date_range.end
        end.sum(&:amount_cents)

        if orders_total + topups_total > 0
          puts "User #{user.email_address} - Sales: "\
               "#{orders_total + topups_total} - Refunds: #{refunds_total}"
        end

        total_sales += orders_total - refunds_total + topups_total
      end

      total_sales
    end
end
