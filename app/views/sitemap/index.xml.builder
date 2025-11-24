xml.instruct! :xml, version: "1.0"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @urls.each do |url_data|
    xml.url do
      xml.loc url_data[:loc]
      xml.lastmod url_data[:lastmod].strftime("%Y-%m-%d") if url_data[:lastmod]
      xml.changefreq url_data[:changefreq] if url_data[:changefreq]
      xml.priority url_data[:priority] if url_data[:priority]
    end
  end
end
