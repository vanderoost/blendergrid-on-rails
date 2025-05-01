module UrlHelper
  def on_page?(path)
    unless request
              raise "You cannot use helpers that need to determine the current " \
                    "page unless your view context provides a Request object " \
                    "in a #request method"
    end

    return false unless request.get? || request.head?

    return true if request.path == path

    return false if path == "/"

    request.path.starts_with?(path)
  end
end
