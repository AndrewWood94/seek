module ObservationUnitsHelper
  # the selection dropdown box for selecting the study for an observation_unit
  def observation_unit_study_selection(element_name, current_study)
    grouped_options = grouped_options_for_study_selection(current_study)
    blank = current_study.blank? ? 'Not specified' : nil
    disabled = current_study && !current_study.can_edit?
    options = grouped_options_for_select(grouped_options, current_study.try(:id))
    select_tag(element_name, options,
               class: 'form-control', include_blank: blank, disabled: disabled).html_safe
  end
end
