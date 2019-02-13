module TimelinesHelper
  def timeline_human_friendly_visibility(visibility)
    content_tag(:span,
      safe_join([icon_only_visibility(visibility),t("timeline.#{visibility}Text")], ' '),
      class: "human_friendly_visibility_#{visibility}",
      title: timeline_visibility_description(visibility))
  end

  def timeline_icon_only_visibility(visibility)
    icon = case visibility
      when Timeline::PUBLIC
        "fa-globe"
      when Timeline::PRIVATE
        "fa-lock"
      else
        "fa-link"
    end
    content_tag(:span, '', class:"fa #{icon} fa-lg", title: visibility_description(visibility))
  end

  def timeline_visibility_description(visibility)
    t("timeline.#{visibility}AltText")
  end
end
