module TimeHelper
  def time_ago_in_words(time)
    seconds_ago = Time.now - time

    if seconds_ago < 10
      return "just now"
    end

    self.duration_in_words(seconds_ago * 1000) + " ago"
  end

  def duration_in_words(ms)
    ms = ms.round unless ms.is_a?(Integer)

    sign = ms < 0 ? "-" : ""
    ms = ms.abs

    seconds, ms = ms.divmod(1000)
    minutes, seconds = seconds.divmod(60)
    hours, minutes = minutes.divmod(60)
    days, hours = hours.divmod(24)

    if days > 2
      "#{sign}#{days} days"
    elsif hours > 9
      "#{sign}#{hours}h"
    elsif hours > 0
      format("%s%d:%02dh", sign, hours, minutes)
    elsif minutes > 9
      format("%s%dm", sign, minutes)
    elsif minutes > 0
      format("%s%d:%02dm", sign, minutes, seconds)
    elsif seconds > 9
      "#{sign}#{seconds}s"
    elsif seconds > 0
      format("%s%.1fs", sign, seconds + ms / 1000)
    else
      format("%s%d.%03ds", sign, seconds, ms)
    end
  end
end
