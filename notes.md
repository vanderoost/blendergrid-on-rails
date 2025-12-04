1. Let's store it as an integer under `reward_percent` (it will never be a partial
   percentage anyway).

2. Good point, I agree.

3. Yep, I think paid_out_at is nicer than a boolean, more useful information. If I
   eventually manage to automate the payouts, maybe those have to be tracked in a table
as well, and the affilliate_monthly_stats table might need to reference that. But that
can be added later.

4. Maybe instead of `resources :affiliates` we can make it the same as `account`. Just a
   single resource. Because it doesn't make sense for a logged in User to be accessing
multiple affiliates. They either are an affiliate or not. It does make sense for the
monthly stats to have an #index and not a $show. Becuase you're indexing multiple
months at a time. Another option is to put everything under `account`, since for now
that's the view where the affiliate stats show up. Like this:

```ruby
# config/routes.rb
resource :account, only: [:show] do
  resources :monthly_affiliate_stats, only: [:index]
end
```

---

1. How to track sales from attributed users?
We have to check all the Orders of the user and use the cash_cents column.
Another way Users can pay is not by creating Orders directly, but by buying credit. This
is handled by the CreditEntry model (only when the reason is topup, then we count the
`amount_cents` column).

Only count sales in the specific month we want to calculate the stats for.

And not only first purchases, but all purchases up to 12 months after the User signed up
(`created_at`). After that we stop rewarding. Maybe this 12 months value could also be
stored in the Affiliate model.

2. Only unique visitors that viewed the landing page. We can track the amount of
   unique requests where the Event is "showed page variant that belongs to landing
page". We'll have to come up with a fast query to pull this data out.
