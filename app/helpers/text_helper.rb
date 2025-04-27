module TextHelper
  def middle_truncate(text, n = 48)
    text = text.to_s
    if text.length <= n
      text
    else
      start_length = [ (n/2.0).floor - 1, 0 ].max
      end_length = [ (n/2.0).ceil - 1, 1 ].max
      "#{text[..start_length]}…#{text[-end_length..]}"
    end
  end
end
