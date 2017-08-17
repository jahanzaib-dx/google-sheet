module ImportTemplateValidator

  def self.validate(model, section=nil)
    valid = (['map_details', 'mapping_structure'].include? section ) ?  model.fields_valid?([:name]) : model.valid?
    errors = (model.field_errors) ? model.errors.to_hash.merge(model.field_errors) : model.errors
    res = { valid: valid, errors: {} }
    res[:errors][model.class.to_s.underscore] = errors
    res
  end

end
