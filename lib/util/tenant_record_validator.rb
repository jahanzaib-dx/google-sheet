module TenantRecordValidator

  def self.validate(model, section=nil)
    valid = (section.nil?) ? model.valid? : model.fields_valid?(model.property_group(section))
    errors = (model.field_errors) ? model.errors.to_hash.merge(model.field_errors) :  model.errors

    res = { valid: valid, errors: {} }
    res[:errors][model.class.to_s.underscore] = errors
    res
  end
end
