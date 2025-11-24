class SitemapController < ApplicationController
  allow_unauthenticated_access

  def index
    @urls = [
      { loc: root_url, changefreq: "daily", priority: 1.0 },
      { loc: pricing_url, changefreq: "monthly", priority: 0.8 },
      { loc: support_url, changefreq: "monthly", priority: 0.8 },
      { loc: policies_url, changefreq: "monthly", priority: 0.8 },
      { loc: policy_url("terms"), changefreq: "monthly", priority: 0.8 },
      { loc: policy_url("privacy"), changefreq: "monthly", priority: 0.8 },
      { loc: policy_url("refund"), changefreq: "monthly", priority: 0.8 },
    ]

    @urls += Article.published.map do |article|
      {
        loc: article_url(article),
        lastmod: article.updated_at,
        changefreq: "weekly",
        priority: 0.7,
      }
    end

    response.headers["Content-Type"] = "application/xml; charset=utf-8"
  end
end
