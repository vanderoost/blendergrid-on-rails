// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Helpers
export function pluralize(count, singular, plural = '') {
    const word = count === 1 ? singular : plural || singular + 's'
    return `${count} ${word}`
}
