$(document).ready ->
  $('#bulk-comp-continue-1').on 'click', ->
    property_type_value = $('.property-type-dropdown').val()
    if property_type_value != ''
      $('#bulk_property_type_switch').val property_type_value
      $('.is-active .tick span').css 'color', 'green'
      $('.is-active .tick span').css 'color', '#ececef'
      if property_type_value == 'lease_comps'
        open_next_accordian_item 'accordian-item1-a', 'accordian-item1'
        $('#bulk-custom-comp-dynamic-content, #bulk-sales-comp-dynamic-content').hide()
        $('#bulk-lease-comp-dynamic-content').show()
      else if property_type_value == 'custom_data'
        open_next_accordian_item 'accordian-item2', 'accordian-item1'
        $('#bulk-lease-comp-dynamic-content, #bulk-sales-comp-dynamic-content').hide()
        $('#bulk-custom-comp-dynamic-content').show()
      else if property_type_value == 'sales_comps'
        open_next_accordian_item 'accordian-item2', 'accordian-item1'
        $('#bulk-lease-comp-dynamic-content, #bulk-custom-comp-dynamic-content').hide()
        $('#bulk-sales-comp-dynamic-content').show()
    else
      $(this).addClass('invalid')

  $('#bulk-comp-continue-2').on 'click', (e) ->
    e.preventDefault()
    $('.is-active .tick span').css 'color', 'green'
    open_next_accordian_item 'accordian-item3', 'accordian-item2'
    $('.is-active .tick span').css 'color', '#ececef'
    add_operating_expenses_rows()


  $('#bulk-comp-continue-3').on 'click', ->
    $('.is-active .tick span').css 'color', 'green'
    open_next_accordian_item 'accordian-item4', 'accordian-item3'
    $('.is-active .tick span').css 'color', '#ececef'
    if( $('#tenant_record_free_rent_type_consecutive').prop('checked') or  $('#tenant_record_free_rent_type_consecutive').prop('checked') or  $('#tenant_record_free_rent_type_consecutive').prop('checked'))
      $('tr.tenant-free-rent-row').show()
    else
      $('tr.tenant-free-rent-row').hide()
    if $('#geo_code_records').prop('checked')
      $('tr.tenant-address-row').show()
    else
      $('tr.tenant-address-row').hide()




  ###$('#bulk-comp-continue-4').on 'click', ->
    $('.is-active .tick span').css 'color', 'green'
    open_next_accordian_item 'accordian-item5', 'accordian-item4'
    $('.is-active .tick span').css 'color', '#ececef'###

  $('#bulk-comp-continue-1-a').on 'click', (e) ->
      radio = $('input[type=radio][name=service_type]:checked')
      if(radio.val() == 'self')
        $('#self-service-content').show();
        $('#white-glove-service').hide();
        open_next_accordian_item 'accordian-item2', 'accordian-item1-a'
      else
        $('#white-glove-service').show();
        $('#self-service-content').hide();
        open_next_accordian_item 'accordian-item2-a', 'accordian-item1-a'

  $('#bulk-comp-continue-2-a').on 'click' , (e) ->
    $(this).parents('.accordion-content').find('form').trigger('submit');

  $('.fileToUpload_white_glove').on 'change', ->
    fullPath = $('.fileToUpload_white_glove').val()
    if fullPath
      startIndex = if fullPath.indexOf('\\') >= 0 then fullPath.lastIndexOf('\\') else fullPath.lastIndexOf('/')
      filename = fullPath.substring(startIndex)
      if filename.indexOf('\\') == 0 or filename.indexOf('/') == 0
        filename = filename.substring(1)
      $('.uploaded_file_name').html('You have selected "<b>' + filename + '</b>"').show()

  $(document).on 'change', '.bulk-column-header-dd', (e) ->
    $(@).parent().siblings('.first').find('.bulk-column-header-value').val($(@).find(":selected").text())

#  $(document).on 'click', '#bulk-comp-continue-3, #bulk-sales-comp-continue-2, #bulk-custom-comp-continue-2', (e) ->
#    submit_is = $(@)
##    submit_is.closest('form').submit()
#    submit_is.parent().siblings('.accordion-content-data').find('.bulk-upload-file-section').find('form').trigger("submit")

  $(document).on 'change','#fileToUpload.self-service', (e) ->
    submit_is = $('#bulk-comp-continue-3, #bulk-sales-comp-continue-2, #bulk-custom-comp-continue-2')
    loadingAnimationStarts()
    submit_is.parent().siblings('.accordion-content-data').find('.bulk-upload-file-section').find('form').trigger("submit")

  $(document).on 'click', '#bulk-comp-continue-4, #bulk-sales-comp-continue-4, #bulk-custom-comp-continue-3', (e) ->
    error = false;
    $('.accordion-custom :input').each (e) ->
      if $(this).hasClass('validate[required]') && $(this).is(':visible')
        if( !$(this).validationEngine('validate') )
          error = true;

    if(!error)
      form_data = $('.accordion-custom :input').serializeArray();
      console.log(form_data)
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
    if $('#geo_code_records_sales').prop('checked')
      $('tr.sales-address-row').show()
    else
      $('tr.sales-address-row').hide()
    if $("input[type='radio'][name='sale_record[is_sales_record]']:checked").length > 0 and $("input[type='radio'][name='sale_record[is_sales_record]']:checked").val() == 'yes'
      $('.building-row').hide()
      $('.land-row').show()
      $('.building-row input, .building-row select').attr('disabled','disabled')
      $('.land-row input, .land-row select').removeAttr('disabled')

    if $("input[type='radio'][name='sale_record[is_sales_record]']:checked").length > 0 and $("input[type='radio'][name='sale_record[is_sales_record]']:checked").val() == 'no'
      $('.building-row').show()
      $('.land-row').hide()
      $('.building-row input, .building-row select').removeAttr('disabled')
      $('.land-row input, #sales-land-table select').attr('disabled','disabled')


  $('input[type=checkbox][id=custom_record_is_geo_coded].bulk-upload').on 'change', (e) ->
    obj = $(this)
    rightBox = obj.parents(".accordion-content").find(".right-box")
    if(obj.is(":checked"))
      rightBox.find(".accordion-content-continue:first").show()
      rightBox.find(".accordion-content-continue:last").hide()
      obj.parents("li").next().show();
    else
      rightBox.find(".accordion-content-continue:first").hide()
      rightBox.find(".accordion-content-continue:last").show()
      obj.parents("li").next().hide();


  $('input[type=radio][name=lease_structure]').on 'change', (e) ->
    radio = $(this)
    if( radio.val() == 'yes')
      $('.operating-expenses-wrapper').show();
      $('.lease-structure-mapping-row').show();
    else
      $('.operating-expenses-wrapper').hide();
      $('.lease-structure-mapping-row').hide();

  $('input[type=radio][name=operating_expenses]').on 'change', (e) ->
    radio = $(this)
    if( radio.val() == 'yes')
      $('.operating-expenses-columm-count').show();
    else
      $('.operating-expenses-columm-count').hide();

add_operating_expenses_rows = ->
  html = $('.operating-expenses-mapping-row').html()
  count = $('#oe_column_count').val()
  if($('input[type=radio][name=operating_expenses]:checked').val()=='yes' && $('input[type=radio][name=lease_structure]:checked').val()=='yes')
    $('.operating-expenses-mapping-row').show()
    $('.operating-expenses-mapping-row-count').remove()
    if ( count > 1 )
      for i in [2..count]
        $('.operating-expenses-mapping-row:last').after('<tr class="operating-expenses-mapping-row operating-expenses-mapping-row-count">'+html+'</tr>')
        $('.operating-expenses-mapping-row:last td:first-child span:first-child').html(i)
        $('.operating-expenses-mapping-row:last').show()
  else
    $('.operating-expenses-mapping-row').hide()


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




$(document).on 'click', '#tenant_record_rent_escalation_type_percent', (e) ->
  if $(this).is(":checked")
    $('input[type=text][name="tenant_record[escalation]"]').parents('tr').show();
  else
    $('input[type=text][name="tenant_record[escalation]"]').parents('tr').hide();


$(document).on 'click', '#tenant_record_rent_escalation_type_fixed', (e) ->
  if $(this).is(":checked")
    $('input[type=text][name="tenant_record[fixed_escalation]"]').parents('tr').show();
  else
    $('input[type=text][name="tenant_record[fixed_escalation]"]').parents('tr').hide();


$(document).on 'ready', ->
  $('input[type=text][name="tenant_record[escalation]"]').parents('tr').hide();
  $('input[type=text][name="tenant_record[fixed_escalation]"]').parents('tr').hide();


window.populateHeaderSelect = ->
  $('.bulk-column-header-dd').each  (i, obj) ->
    if($(obj).children('option').length < 1)
      $(obj).html(options);


#*************************************************** Google addresses Api start *******************************#
#placeSearch = undefined
#autocomplete = undefined
#autocomplete2 = undefined
#autocomplete3 = undefined
#componentForm =
#  street_number: 'short_name',
#  route: 'long_name',
#  locality: 'long_name'
#  administrative_area_level_1: 'short_name'
#  country: 'long_name'
#
#initAutocomplete = ->
## Create the autocomplete object, restricting the search to geographical
## location types.
#  autocomplete = new (google.maps.places.Autocomplete)(document.getElementById('autocomplete'), types: [ 'geocode' ])
#  autocomplete.addListener 'place_changed', ->
#    fillInAddress autocomplete, ''
#
#  autocomplete2 = new (google.maps.places.Autocomplete)(document.getElementById('autocomplete2'), types: [ 'geocode' ])
#  autocomplete2.addListener 'place_changed', ->
#    fillInAddress autocomplete2, '2'
#
#  autocomplete3 = new (google.maps.places.Autocomplete)(document.getElementById('autocomplete3'), types: [ 'geocode' ])
#  autocomplete3.addListener 'place_changed', ->
#    fillInAddress autocomplete3, '3'
#
#  autocomplete4 = new (google.maps.places.Autocomplete)(document.getElementById('autocomplete4'), types: [ 'geocode' ])
#  autocomplete4.addListener 'place_changed', ->
#    fillInAddress autocomplete4, '4'
#  return
#
#fillInAddress = (autocomplete, unique) ->
## Get the place details from the autocomplete object.
#  place = autocomplete.getPlace()
#  for component of componentForm
#    if ! !document.getElementById(component + unique)
#      document.getElementById(component + unique).value = ''
#      document.getElementById(component + unique).disabled = false
#  # Get each component of the address from the place details
#  # and fill the corresponding field on the form.
#  i = 0
#  while i < place.address_components.length
#    addressType = place.address_components[i].types[0]
#    if componentForm[addressType] and document.getElementById(addressType + unique)
#      val = place.address_components[i][componentForm[addressType]]
#      document.getElementById(addressType + unique).value = val
#    i++
#  document.getElementById('autocomplete' + unique).value = document.getElementById('street_number' + unique).value + ' ' + document.getElementById('route' + unique).value
#  return
#
#geolocate = ->
#  if navigator.geolocation
#    navigator.geolocation.getCurrentPosition (position) ->
#      geolocation =
#        lat: position.coords.latitude
#        lng: position.coords.longitude
#      circle = new (google.maps.Circle)(
#        center: geolocation
#        radius: position.coords.accuracy)
#      autocomplete.setBounds circle.getBounds()
#  return
#
#window.onload = ->
#  initAutocomplete()
#  return

#*************************************************** Google addresses Api end *******************************#