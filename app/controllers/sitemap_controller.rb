class SitemapController < ApplicationController
  allow_unauthenticated_access

  def index
    mod_date = Date.new(2025, 11, 24)
    @urls = [
      { loc: root_url, lastmod: mod_date },
      { loc: faqs_url, lastmod: mod_date },
      { loc: pricing_url, lastmod: mod_date },
      { loc: support_url, lastmod: mod_date },
      { loc: policies_url, lastmod: mod_date },
      { loc: policy_url("terms"), lastmod: mod_date },
      { loc: policy_url("privacy"), lastmod: mod_date },
      { loc: policy_url("refund"), lastmod: mod_date },
    ]

    @urls += Article.published.map do |article|
      {
        loc: article_url(article),
        lastmod: article.updated_at,
      }
    end

    response.headers["Content-Type"] = "application/xml; charset=utf-8"
  end
end
