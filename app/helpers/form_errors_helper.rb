module FormErrorsHelper
  # The validation messages of one attribute, printed right below its field, e.g.
  #   <%= form.number_field :monthly_rent, class: "form-control" %>
  #   <%= field_error form.object, :monthly_rent %>
  def field_error(record, attribute)
    messages = record.errors.full_messages_for(attribute)
    return if messages.empty?

    tag.div safe_join(messages, tag.br), class: "invalid-feedback d-block", id: "#{attribute}_error"
  end
end
