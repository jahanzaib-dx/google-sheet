$(document).ready ->
  $('#bulk-comp-continue-1').on 'click', ->
    property_type_value = $('.property-type-dropdown').val()
    if property_type_value != ''
      $('#bulk_property_type_switch').val property_type_value
      $('.is-active .tick span').css 'color', 'green'
      open_next_accordian_item 'accordian-item2', 'accordian-item1'
      $('.is-active .tick span').css 'color', '#ececef'
      if property_type_value == 'lease_comps'
        $('#bulk-custom-comp-dynamic-content, #bulk-sales-comp-dynamic-content').hide()
        $('#bulk-lease-comp-dynamic-content').show()
      else if property_type_value == 'custom_data'
        $('#bulk-lease-comp-dynamic-content, #bulk-sales-comp-dynamic-content').hide()
        $('#bulk-custom-comp-dynamic-content').show()
      else if property_type_value == 'sales_comps'
        $('#bulk-lease-comp-dynamic-content, #bulk-custom-comp-dynamic-content').hide()
        $('#bulk-sales-comp-dynamic-content').show()
    else
      $(this).addClass('invalid')

  $('#bulk-comp-continue-2').on 'click', (e) ->
    e.preventDefault()
    $('.is-active .tick span').css 'color', 'green'
    open_next_accordian_item 'accordian-item3', 'accordian-item2'
    $('.is-active .tick span').css 'color', '#ececef'

  $('#bulk-comp-continue-3').on 'click', ->
    $('.is-active .tick span').css 'color', 'green'
    open_next_accordian_item 'accordian-item4', 'accordian-item3'
    $('.is-active .tick span').css 'color', '#ececef'

  $('#bulk-comp-continue-4').on 'click', ->
    $('.is-active .tick span').css 'color', 'green'
    open_next_accordian_item 'accordian-item5', 'accordian-item4'
    $('.is-active .tick span').css 'color', '#ececef'

  $(document).on 'change', '.bulk-column-header-dd', (e) ->
    $(@).parent().siblings('.first').find('.bulk-column-header-value').val($(@).find(":selected").text())

  $(document).on 'click', '#bulk-comp-continue-3, #bulk-sales-comp-continue-2, #bulk-custom-comp-continue-2', (e) ->
    console.log('clickeddddddddddddddddddddddddddddddd')
    submit_is = $(@)
#    submit_is.closest('form').submit()
    submit_is.parent().siblings('.accordion-content-data').find('.bulk-upload-file-section').find('form').trigger("submit")

  $(document).on 'click', '#single-comp-continue-4, #bulk-sales-comp-continue-4, #bulk-custom-comp-continue-3', (e) ->
    form_data = $('.accordion-custom :input').serializeArray();

    xhr = $.ajax
      url: 'create_and_process_upload'
      method: 'post'
      dataType: 'json',
      data: form_data
    xhr.done (response) ->
      console.log "succesful"
      window.location = "/uploader/import";
    xhr.error (response) ->
      console.log "failed..."
      console.log response


  $('#bulk-sales-comp-continue-2').on 'click', (e) ->
    e.preventDefault()
    $('.is-active .tick span').css 'color', 'green'
    open_next_accordian_item 'accordian-item3', 'accordian-item2'
    $('.is-active .tick span').css 'color', '#ececef'

  $('#bulk-sales-comp-continue-3').on 'click', (e) ->
    e.preventDefault()
    $('.is-active .tick span').css 'color', 'green'
    open_next_accordian_item 'accordian-item4', 'accordian-item3'
    $('.is-active .tick span').css 'color', '#ececef'

open_next_accordian_item = (to_show,to_hide) ->
  $('.'+to_show).addClass('is-active')
  $('.'+to_show + ' a').attr('aria-selected', true)
  $('.'+to_show + ' a').attr('aria-expanded', true)
  $('.'+to_show + ' .accordion-content').attr('aria-hidden', false)
  $('.'+to_show + ' .accordion-content').slideDown(300)

  $('.'+to_hide).removeClass('is-active')
  $('.'+to_hide + ' a').addClass('processed')
  $('.'+to_hide + ' a').attr('aria-selected', false)
  $('.'+to_hide + ' a').attr('aria-expanded', false)
  $('.'+to_hide + ' .accordion-content').attr('aria-hidden', true)
  $('.'+to_hide + ' .accordion-content').slideUp(300)

$(document).on 'click', '.validate-import-record', (e)->
  e.preventDefault()
  section = $(@).closest('table')
  data = _.object _.map(section
  .find(':input')
  .serializeArray(), (i) -> [i.name, i.value]
  )
  form = $(@).closest('form')

  xhr = $.ajax
    url: form.attr('action')
    method: 'put'
    dataType: 'json'
    data: data

  xhr.done (d) ->
    $('#import-fields-' + d.section).replaceWith('<div class="validating"><p>Validating...</p></div>') if d and d.section

  xhr.fail (xhr,ts,err) ->
    alert('Server Error')

  return false

$(document).on 'click', '.view-import-record', (e) ->
  e.preventDefault()
  section = $(@).closest('table')
  section.find('tr.valid').toggle()
  return false

# generate additional Tenant & LL Allowances fields dynamically
$(document).on 'change', '#tenant_record_additional_tenant_cost, #tenant_record_additional_ll_allowance', (e) ->
  count = parseInt( $(this).val() )

  if $(this).attr("id") == "tenant_record_additional_tenant_cost"
    type = "tenant"
    header = "Tenant"
  else
    type = "ll"
    header = "LL"

  $('.additional-allowance-' + type).remove()

  i = 0
  html = ''
  if count
    while i < count
      params = { index: i+1, type: type, header: header }
      html += Mustache.render($('#additional_cost_tenant_template').html(), params )
      i++;
  else
    $('.additional-allowance-' + type).remove()

  $('.lease-record-section table tbody').append html

# show / hide max. number of steps dropdown if comp has stepped rents
$(document).on 'change', '#tenant_record_rent_escalation_type_stepped', (e) ->
  elem = $('#max-stepped-rent-dd')
  if $(this).prop('checked')
    elem.show()
  else
    elem.hide()


# generate stepped rent fields dynamically
$(document).on 'change', '#steps_count_dd', (e) ->
  $('.stepped-rent-row').remove()

  count = parseInt( $(this).val() )
  i = 0
  html = ''
  if count
    while i < count
      params = { index: i+1 }
      html += Mustache.render($('#stepped_rent_bulk_template').html(), params )
      i++
  else
    $('.stepped-rent-row').hide()

  $('.lease-record-section table tbody').append html