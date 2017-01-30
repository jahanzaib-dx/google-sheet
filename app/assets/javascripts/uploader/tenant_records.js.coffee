$AJAX_BASE_URL = '/uploader/ajax/'
stepped_rent_popup = null

call_ajax_and_setup_expense = (container) ->
  xhr = $.ajax
    url: $AJAX_BASE_URL + 'market_expenses_list/' + $('.market-for-expense').val()
    method: 'get'
    dataType: 'json'

  xhr.done (response) ->
    other_expenses = {}
    total_opex     = {}
    modified_gross = {}
    result = JSON.parse(JSON.stringify(response[0]))

    $.each result, (key, value) ->
      if key == 'total_opex'
        total_opex[key] = value
      else
        other_expenses[key] = value

    container.empty()
    lease_structure = $('#lease_structure_name').val()
    if $('#lease_structure_name').val() == 'NNN'
      selected_option = 1
      $.each other_expenses, (key, value) ->
        html_dd = expense_dd_options_selected(other_expenses, selected_option)
        selected_option += 1
        row = container.find('tr').length - 1 + 1
        container.append(Mustache.render($('#expense-row-tmpl-dynamic').html(), { row: '_new_' + row, expense_dd_options: html_dd, default_expense: value }))
        current_elem = $('#expense_new_' + row)
        $(current_elem).siblings('input.custom-expense-actual-value').val($(current_elem).val())

    else if $('#lease_structure_name').val() == 'Full Service'
      selected_option = 1
      $.each total_opex, (key, value) ->
        html_dd = expense_dd_options_selected(total_opex, selected_option)
        selected_option += 1
        row = container.find('tr').length - 1 + 1
        container.append(Mustache.render($('#expense-row-tmpl-dynamic').html(), { row: '_new_' + row, expense_dd_options: html_dd, default_expense: value }))
        current_elem = $('#expense_new_' + row)
        $(current_elem).siblings('input.custom-expense-actual-value').val($(current_elem).val())

      $('.lease-structure-calc-type').val('with_start_and_base_year')

    else if $('#lease_structure_name').val() == 'Modified Gross'
      modified_gross['total_opex'] = round_up_to_2_decimal(parseFloat(result['total_opex']) - parseFloat(result['utilities']))
      modified_gross['utilities'] = result['utilities']
      selected_option = 1
      $.each modified_gross, (key, value) ->
        html_dd = expense_dd_options_selected(modified_gross, selected_option)
        selected_option += 1
        row = container.find('tr').length - 1 + 1
        container.append(Mustache.render($('#expense-row-tmpl-dynamic').html(), { row: '_new_' + row, expense_dd_options: html_dd, default_expense: value }))
        current_elem = $('#expense_new_' + row)
        $(current_elem).siblings('input.custom-expense-actual-value').val($(current_elem).val())
        $('.lease-structure-calc-type').first().val('with_start_and_base_year')
        $('#test-discount').val(3.00)

    xhr.fail (xhr, ts, err) ->
      container.empty()

    date_picker_setup()
    activate_auto_selection()

activate_auto_selection = ->
  $(document).on 'click', "input[type='text']", (e) ->
    $(this).select()

date_picker_setup = ->
  $('.date-picker-inline').fdatepicker().on('changeDate', (ev) ->
    if ev.date
      newDate = new Date(ev.date)
      formatted_lcd = newDate.getFullYear() + '-' + (newDate.getMonth() + 1) + '-' + newDate.getDate()
      $(this).parent().find('span input').val(formatted_lcd)
  ).data 'datepicker'

$('.tenant-record-map-view').each ->
  icon =
    scaledSize: new google.maps.Size 200, 300
    url: '/assets/tenantrex-marker.png'

  address = $(@).data('address')
  latitude = parseFloat($(@).data('latitude'))
  longitude = parseFloat($(@).data('longitude'))
  container = $(@).get(0)
  options =
    mapTypeId: google.maps.MapTypeId.ROADMAP
    center: new google.maps.LatLng(latitude, longitude)
    zoom: 14
  unless address.length > 0
    geo = new google.maps.Geocoder()
    geo.geocode { 'address': address }, (results, status) ->
      if (status == google.maps.GeocoderStatus.OK)
        options.center = results[0].geometry.location
      map = new google.maps.Map container, options
      new google.maps.Marker
        position: options.center
        icon: icon
        map: map
  else
    map = new google.maps.Map container, options
    new google.maps.Marker
      position: options.center
      icon: icon
      map: map



$(document).on 'click', '#single-comp-continue-4, #sales-comp-continue-3, #custom-comp-continue-3', (e) ->
  e.preventDefault()
  submit_is = $(@).closest('form')
  if submit_is.validationEngine('validate')
    submit_is.submit()

$(document).ready ->
  select_increase_rent_type()
  localStorage.removeItem("expense_types");
  #*********** Add "other" dynamically in single comp dropdown ***********#
  $('.custom-value-dropdown').each (i, obj) ->
    $('#'+obj.id).append $('<option/>',
      value: 'other'
      text: 'Other')
  #************************************************************************#

  $(document).on 'focusout', '.number-of-months-field', (e) ->
    lease_term = 0
    sum = 0

    lease_term = parseInt( $('#tenant_record_lease_term_months').val() ) if $('#tenant_record_lease_term_months').val()
    $('.number-of-months-field').each (i, item) ->
      sum += parseInt( $(item).val() ) if $(item).val()

    if sum > lease_term
      $('.stepped-rent-row.error-message td').html "'Lease Term Months' must be EQUAL to 'number of steps months'"
      $('.stepped-rent-row.error-message').css('display', 'block')
      $('.stepped-rent-row.info').css('display', 'none')
    else
      remaining_months = lease_term - sum
      $('.stepped-rent-row.info td').html remaining_months + " Months Remaining"
      $('.stepped-rent-row.info').css('display', 'block')
      $('.stepped-rent-row.error-message').css('display', 'none')


  # show / hide element on dom ready event
  unless $('#tenant_record_is_tenant_improvement').prop('checked')
    $('tr.tenant-improvement-row').hide()

  unless $('#tenant_record_free_rent_type_consecutive:checked').val()=='consecutive' && $('#tenant_record_free_rent_type_non_consecutive:checked').val()=='non_consecutive'
    $('tr.free-rent-row').hide()
  # end

  $('#steps_count').on 'change', ->
    $('.stepped-rent-row').remove()

    count = parseInt( $(this).val() )
    i = 0
    html = ''
    if count
      while i < count
        params = { index: i+1, last: (count == i+1) }
        html += Mustache.render($('#stepped_rent_new_layout_template').html(), params )
        i++
    else
      $('.stepped-rent-row').hide()

    $('.lease-comp-single table tbody').append html

  $(document).foundation()
  date_picker_setup()

  $('.is-active .tick span').css 'color', '#ececef'

  #******** Sales Comp ******************#

  $('#sales-comp-continue-2').on 'click', (e) ->
    e.preventDefault()
    $('.is-active .tick span').css 'color', 'green'
    open_next_accordian_item 'accordian-item3', 'accordian-item2'
    $('.is-active .tick span').css 'color', '#ececef'

    if $("input[type='radio'][name='sale_record[is_sales_record]']:checked").length > 0 and $("input[type='radio'][name='sale_record[is_sales_record]']:checked").val() == 'yes'
      $('#sales-building-table').hide()
      $('#sales-land-table').show()
      $('#sales-building-table input, #sales-building-table select').attr('disabled','disabled')
      $('#sales-land-table input, #sales-land-table select').removeAttr('disabled')
      $('.land-size-unit-container').css 'display', 'block'


    if $("input[type='radio'][name='sale_record[is_sales_record]']:checked").length > 0 and $("input[type='radio'][name='sale_record[is_sales_record]']:checked").val() == 'no'
      $('#sales-building-table').show()
      $('#sales-land-table').hide()
      $('#sales-building-table input, #sales-building-table select').removeAttr('disabled')
      $('#sales-land-table input, #sales-land-table select').attr('disabled','disabled')


  $(".sale-record").on 'click', ->
    selected = $("input[type='radio'][name='sale_record[is_sales_record]']:checked")
    if selected.length > 0 and selected.val() == 'no'
      $('.land-size-unit-container').css 'display', 'none'
    else
      $('.land-size-unit-container').css 'display', 'block'

  $("input[type=radio][name='sale_record[land_size_identifier]']").on 'click' , ->
    selected = $("input[type='radio'][name='sale_record[land_size_identifier]']:checked")
    if selected.length > 0 and selected.val() == 'acres'
      $('#sale_record_land_size').attr('placeholder','Acres')
    else
      $('#sale_record_land_size').attr('placeholder','SF')
  #***************************************#


  #******************* Custom Data *********************#

  $('#custom-comp-continue-2').on 'click', (e) ->
    e.preventDefault()
    if $("input[type='radio'][name='custom_record[is_existing_data_set]']:checked").length > 0
      if $("input[type='radio'][name='custom_record[is_existing_data_set]']:checked").val() == 'yes'
        #send ajax request
      else if $("input[type='radio'][name='custom_record[is_existing_data_set]']:checked").val() == 'no'
        if $('.geo-code-my-records').is(':checked')
          html_default_fields = Mustache.render $('#default-fields-geo-code-selection').html()
          $('.fields-table-custom-data table tbody').html html_default_fields
          initAutocomplete()
        else
          $('.fields-table-custom-data table tbody').empty()
        html_add_row = Mustache.render $('#add-button-geo-code-selection').html()
        $('.fields-table-custom-data table tfoot').html html_add_row

    $('.is-active .tick span').css 'color', 'green'
    open_next_accordian_item 'accordian-item3', 'accordian-item2'
    $('.is-active .tick span').css 'color', '#ececef'

  #*************** Bulk Custom Data ***************#
  $('#bulk-custom-comp-continue-2').on 'click', (e) ->
    e.preventDefault()
    if $("input[type='radio'][name='custom_record[is_existing_data_set]']:checked").length > 0
      if $("input[type='radio'][name='custom_record[is_existing_data_set]']:checked").val() == 'yes'
        #send ajax request
      else if $("input[type='radio'][name='custom_record[is_existing_data_set]']:checked").val() == 'no'
        if $('.geo-code-my-records').is(':checked')
          html_default_fields = Mustache.render $('#bulk-default-fields-geo-code-selection').html()
          $('.fields-table-custom-data table tbody').html html_default_fields
        else
          $('.fields-table-custom-data table tbody').empty()
        html_add_row = Mustache.render $('#add-new-row-button-bulk-upload').html()
        $('.fields-table-custom-data table tfoot').html html_add_row

    $('.is-active .tick span').css 'color', 'green'
    populateHeaderSelect()
    open_next_accordian_item 'accordian-item3', 'accordian-item2'
    $('.is-active .tick span').css 'color', '#ececef'

  #************************************************#

  if $("input[type='radio'][name='custom_record[is_existing_data_set]']:checked").length > 0 and $("input[type='radio'][name='custom_record[is_existing_data_set]']:checked").val() == 'yes'
    $('.existing-data-set-container').css 'display', 'block'
  else if $("input[type='radio'][name='custom_record[is_existing_data_set]']:checked").length > 0 and $("input[type='radio'][name='custom_record[is_existing_data_set]']:checked").val() == 'no'
    $('.new-data-set-container').css 'display', 'block'
  $(".data-set-type").on 'click', ->
    selected = $("input[type='radio'][name='custom_record[is_existing_data_set]']:checked")
    if selected.length > 0
      if selected.val() == 'yes'
        $('#custom_record_name').prop("disabled", true);
        $('.existing-data-set-container').css 'display', 'block'
        $('.new-data-set-container').css 'display', 'none'
      else
        $('#custom_record_name').val('').prop("disabled", false);
        $('.existing-data-set-container').css 'display', 'none'
        $('.new-data-set-container').css 'display', 'block'

  $(document).on 'click', '.add-row-custom-data-geocode-single-comp, .add-row-custom-data-geocode-bulk-upload', (e)->
    e.preventDefault()
    container = $('.fields-table-custom-data')
    row = container.find('.user-defined-custom-data').length
    if( $(this).hasClass("add-row-custom-data-geocode-single-comp") )
      custom_data_set_row = Mustache.render($('#custom-data-set-row-template').html(), {row: row})
    else if( $(this).hasClass("add-row-custom-data-geocode-bulk-upload") )
      custom_data_set_row = Mustache.render($('#custom-data-new-bulk-set-row-template').html(), {row: row})

    $('.fields-table-custom-data table tbody').append custom_data_set_row
    populateHeaderSelect()



  $(document).on 'change', '.existing-data-set-dd', (e)->
    xhr = $.ajax
      url: $AJAX_BASE_URL + 'get_custom_record_attributes/' + $('.existing-data-set-dd').val()
      method: 'get'
      dataType: 'json'

    xhr.done (response) ->
      if $('#bulk_property_type_switch').length > 0
        template1_id = '#bulk-default-fields-geo-code-selection'
        template2_id = '#custom-data-existing-bulk-set-row-template'
      else
        template1_id = '#default-fields-geo-code-selection'
        template2_id = '#custom-data-set-row-template'

      if response.is_geo_coded
        $('#custom_record_is_geo_coded').prop 'checked', true
        html_default_fields = Mustache.render $(template1_id).html()
        $('.fields-table-custom-data table tbody').html html_default_fields
        #$('#custom_record_address1').val(response.address1) if response.address1
        #$('#custom_record_city').val(response.city) if response.city
        #$('#custom_record_state').val(response.state) if response.state

        container = $('.fields-table-custom-data table tbody')
        $.each response.custom_record_properties, (row, obj)->
          row = container.find('.user-defined-custom-data').length
          custom_data_set_row = Mustache.render($(template2_id).html(), {row: row, field: obj.key, field_value: ''})
          $('.fields-table-custom-data table tbody').append custom_data_set_row
      else
        $('#custom_record_is_geo_coded').prop 'checked', false
        container = $('.fields-table-custom-data table tbody')
        container.empty()
        $.each response.custom_record_properties, (row, obj)->
          row = container.find('.user-defined-custom-data').length
          custom_data_set_row = Mustache.render($(template2_id).html(), {row: row, field: obj.key, field_value: ''})
          $('.fields-table-custom-data table tbody').append custom_data_set_row
      $('#custom_record_name').val(response.name)

  #*****************************************************#


  $('#single-comp-continue-1').on 'click', ->
    property_type_value = $('.property-type-dropdown').val()
    if property_type_value != ''
      $('#property_type_switch').val property_type_value
      $('.is-active .tick span').css 'color', 'green'
      open_next_accordian_item 'accordian-item2', 'accordian-item1'
      $('.is-active .tick span').css 'color', '#ececef'
      if property_type_value == 'lease_comps'
        $('#custom-comp-dynamic-content, #sales-comp-dynamic-content').hide()
        $('#lease-comp-dynamic-content').show()
      else if property_type_value == 'custom_data'
        $('#lease-comp-dynamic-content, #sales-comp-dynamic-content').hide()
        $('#custom-comp-dynamic-content').show()
      else if property_type_value == 'sales_comps'
        $('#lease-comp-dynamic-content, #custom-comp-dynamic-content').hide()
        $('#sales-comp-dynamic-content').show()
    else
      $(this).addClass('invalid')

  $('#single-comp-continue-2').on 'click', (e) ->
    e.preventDefault()
    base_rent_model_radio = $("input:radio[name ='tenant_record[base_rent_type]']:checked").val()
    if base_rent_model_radio
      $('.is-active .tick span').css 'color', 'green'
      open_next_accordian_item 'accordian-item3', 'accordian-item2'
      $('.is-active .tick span').css 'color', '#ececef'

  $('#single-comp-continue-3').on 'click', ->
    $('.is-active .tick span').css 'color', 'green'
    open_next_accordian_item 'accordian-item4', 'accordian-item3'
    $('.is-active .tick span').css 'color', '#ececef'

  $('#tenant_record_is_tenant_improvement').on 'click', (e) ->
    elem = $('tr.tenant-improvement-row')
    if $(this).prop('checked')
      elem.show()
    else
      elem.hide()

  $('#tenant_record_free_rent_type_consecutive,#tenant_record_free_rent_type_non_consecutive').on 'change', ->
    if $('#tenant_record_free_rent_type_consecutive:checked').val()=='consecutive' || $('#tenant_record_free_rent_type_non_consecutive:checked').val()=='non_consecutive'
      $('tr.free-rent-row').show()
    else
      $('tr.free-rent-row').hide()

  $('.has-additional-tenant-cost-check, .has-additional-ll-allowance-check').on 'change', ->
    if $(this).is(':checked')
      $(this).parents('.additional-cost-section').find('select').show()
    else
      $(this).parents('.additional-cost-section').find('select').hide()


  #************************ Single comp DropDowns Fields *****************************#
  $('.custom-value-dropdown').on 'change', ->
    $('#expense-table tbody').empty() if $(this)[0].id == "temp_comp_property_type_dd"

    dropdown_value = $(this).val()
    if dropdown_value == 'other'
      $(this).siblings('.custom-value-input').removeAttr('disabled')
      $(this).siblings('.custom-value-input').css('cursor', 'unset')
      $(this).siblings('.actual-value').val($(this).val())
    else
      $(this).siblings('.custom-value-input').attr('disabled', 'disabled')
      $(this).siblings('.custom-value-input').css('cursor', 'not-allowed')
      $(this).siblings('.actual-value').val($(this).val())

  $('.custom-value-input').on 'blur', ->
    $(this).siblings('.actual-value').val($(this).val())
  #********************************************************************************#

  #******************* ***************************#
  $(document).on 'click', '.processed', ->
    open_processed_accordian_item($(this))
  #***********************************************#

  #************************ Single comp DropDowns Expenses *****************************#
  ###$(document).on 'change', '.custom-expense-dd', (e) ->
    dropdown_value = $(this).val()
    if dropdown_value == 'other'
      $(this).siblings('.custom-expense-tf').removeAttr('disabled')
      $(this).siblings('.custom-expense-tf').css('cursor', 'unset')
      $(this).siblings('.custom-expense-actual-value').val($(this).val())
    else
      $(this).siblings('.custom-expense-tf').attr('disabled', 'disabled')
      $(this).siblings('.custom-expense-tf').css('cursor', 'not-allowed')
      $(this).siblings('.custom-expense-actual-value').val($(this).val())

  $(document).on 'blur', '.custom-expense-tf', (e) ->
    $(this).siblings('.custom-expense-actual-value').val($(this).val()) ###
  #********************************************************************************#





  #**********************************************************************************#
  # Unbind Accordian events
  $('.accordion .invalid a').unbind 'click'


  ###$('.accordian-item > a').on 'click', ->
    $(this).find(".tick span").css 'color', '#ececef'
###
  $('.add-custom-data-single-comp').on 'click', (e) ->
    e.preventDefault()

  $("input:radio[name = 'tenant_record[rent_escalation_type]']").on 'click', ->
    select_increase_rent_type()

  select_increase_rent_type()

  #*****************  Add delete custom data row  ***************************#
  $(document).on 'click', '.add-custom-data-single-comp', (e) ->
    e.preventDefault()
    container = $('#custom-fields-table tbody')
    row = container.find('tr').length - 1 + 1
    container.append(Mustache.render($('#custom-field-row-tmpl').html(), { row: '_new_' + row }))
    activate_auto_selection()

  $(document).on 'click', '.delete-custom-field', (e) ->
    e.preventDefault()
    $(@).closest('tr').remove()
  #*****************************************************************************#

  #*****************  Add delete expense row  ***************************#
  $(document).on 'click', '.add-expense-row', (e) ->
    e.preventDefault()
    if localStorage.getItem("expense_types") == null
      xhr = $.ajax
        url: $AJAX_BASE_URL + 'opex_type_list/'
        method: 'get'
        dataType: 'json'
      xhr.done (response) ->
        localStorage.setItem("expense_types", JSON.stringify(response))
        populate_expenses_from_local_storage()
    else
      populate_expenses_from_local_storage()

  $(document).on 'click', '.delete-expense-row', (e) ->
    e.preventDefault()
    $(@).closest('tr').remove()
  #*****************************************************************************#
  # Discount rate and Interest rate default values
  $(document).on 'focusin', '#lease_structure_discount_rate, #lease_structure_interest_rate', (e) ->
    current_value = $(this).val()
    if parseFloat(current_value) == 0.00
      $(this).val('')
  $(document).on 'focusout', '#lease_structure_discount_rate, #lease_structure_interest_rate', (e) ->
    current_value = $(this).val()
    console.log current_value
    if current_value == ''
      $(this).val('0.00')
  #********************* Mini calculator for stepped rent **********************
  $(document).on 'focusin', '.stepped-rent-cost-per-month', (e) ->
    $('#increment-value').val("")
    $('#increment-type').prop 'selectedIndex', 0
    $('#increment-value').attr 'placeholder', 'Enter increment value'
    current_stepped_rent_element = this
    arr = this.id.split('_')
    if arr[1] > 1
      previous_element_id = arr[0] + '_' + (parseInt(arr[1])-1)
      $('#current-rent-number').text('Rent #'+parseInt(arr[1]))
      previous_element_value = $('#' + previous_element_id).val()
      $('#previous-value').html previous_element_value
      $('#current-element-id').val current_stepped_rent_element.id
      $('#previous-element-id').val previous_element_id
      stepped_rent_popup = $('.stepped-rent-increment-bpopup').bPopup(
        modalClose: false )

  $(document).on 'click', '#calculate-current-stepped-rent', (ev) ->
    ev.preventDefault
    ev.stopPropagation
    increment_type = $('#increment-type').val()
    increment_value = $('#increment-value').val()
    previous_element_value = $('#' + $('#previous-element-id').val()).val()
    if parseFloat(increment_value) > 0
      current_stepped_rent_value = 0
      if increment_type == 'fixed'
        current_stepped_rent_value = (parseFloat(previous_element_value) + parseFloat(increment_value)).toFixed(2)
        if isNaN current_stepped_rent_value
          current_stepped_rent_value = 0
        $('#'+$("#current-element-id").val()).val current_stepped_rent_value
      else if increment_type == 'percent'
        current_stepped_rent_value = ((1 + parseFloat(increment_value)/100) * parseFloat(previous_element_value)).toFixed(2)
        if isNaN current_stepped_rent_value
          current_stepped_rent_value = 0
        $('#' + $("#current-element-id").val()).val current_stepped_rent_value
      stepped_rent_popup.close() if stepped_rent_popup

    $(document).on 'click', '#close-stepped-rent-popup', (ev) ->
      ev.preventDefault
      stepped_rent_popup.close() if stepped_rent_popup

  $(document).on 'change', '#increment-type', () ->
    if $(this).val() == 'percent'
      $('#increment-value').attr 'placeholder', 'Value should be integer 2, not .02'
    else
      $('#increment-value').attr 'placeholder', 'Enter increment value'
#***********************************************************************#

#*************** Accordian Customization *******************************#
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

open_processed_accordian_item = (current) ->
  $('.processed .tick span').css 'color', 'rgb(0, 128, 0)'
  current.find('.tick span').css 'color', 'rgb(236, 236, 239)'
  previous = $('.is-active')
  previous.find('a').attr('aria-selected', false)
  previous.find('a').attr('aria-expanded', false)
  previous.find('.accordion-content').attr('aria-hidden', true)
  previous.find('.accordion-content').slideUp(300)
  previous.parent().removeClass('is-active')

  current.attr('aria-selected', true)
  current.attr('aria-expanded', true)
  current.siblings('.accordion-content').attr('aria-hidden', false)
  current.siblings('.accordion-content').slideDown(300)
  current.parent().addClass('is-active')


#***********************************************************************#


#*************** Populate Expenses from local storage *****************#
populate_expenses_from_local_storage =  ->
  expense_dd_html = ''
  response = JSON.parse(localStorage.getItem("expense_types"))
  $.each response, (key, value) ->
    expense_dd_html += '<option value="' + value + '">' + humanize_custom(value) + '</option>'

  container = $('#expense-table tbody')
  row = container.find('tr').length - 1 + 1
  container.append(Mustache.render($('#expense-row-tmpl-dynamic').html(), { row: '_new_' + row, expense_dd_options: expense_dd_html }))
  date_picker_setup()
  activate_auto_selection()
  $('#expense_new_' + row).append $('<option/>',
    value: 'other'
    text: 'Other')

#**********************************************************************

#******************* Jquery Round up to 2 decimal ***************#
round_up_to_2_decimal = (value) ->
  Math.round(value * 100)/100
#*****************************************************************#

#****************  Expense selected option *****************#
expense_dd_options_selected = (options, selected) ->
  html_text = ''
  counter = 1
  $.each options, (a, b) ->
    selection = ''
    if selected == counter
      selection = 'selected'
    html_text = html_text + "\<option value='" + a + "' " + selection + "\>" + humanize_custom(a) + "\</option\>"
    counter += 1
  html_text


#***********************************************************#

#******************** Humanize *****************************#
humanize_custom = (text) ->
  humanized_text = ''
  text_array = text.split("_")
  $.each text_array, (key, value) ->
    if key > 0
      humanized_text += ' ' + value.charAt(0).toUpperCase() + value.substring(1).toLowerCase();
    else
      humanized_text += value.charAt(0).toUpperCase() + value.substring(1).toLowerCase();
  humanized_text

#***********************************************************#

#***** Property type lease structure existence *************#
check_propertyType_leaseStructure_existence = (element_obj) ->
  element_value  = element_obj.val()
  element_dropdown = element_obj.siblings('.custom-value-dropdown')
  if element_dropdown.find('option[value="' + element_value + '"]').length > 0 and element_value != 'other' and element_value != ''
    true
  else
    false
#***********************************************************#

select_increase_rent_type = ->
  rent_increase = $("input:radio[name = 'tenant_record[rent_escalation_type]']:checked").val()
  ###unless rent_increase
    $("input:radio[name = 'tenant_record[rent_escalation_type]']").trigger("click")
    #rent_increase = 'base_rent_percent'###

  if rent_increase == 'base_rent_percent'
    $('.base-rent-row, .sf-percent-increase-row').show()
    $('.sf-fixed-increase-row, .stepped-rent-row, #steps_count, .stepped-rent-text').hide()
  else if rent_increase == 'base_rent_fixed_increase'
    $('.base-rent-row, .sf-fixed-increase-row').show()
    $('.sf-percent-increase-row, .stepped-rent-row, #steps_count, .stepped-rent-text').hide()
  else if rent_increase == 'stepped_rent'
    $('.base-rent-row, .sf-percent-increase-row, .sf-fixed-increase-row').hide()
    $('.stepped-rent-row, .stepped-rent-text, #steps_count').show()
    $('#steps_count').parents('div').show()


#************ Delay start popup ******************#

datepicker_options =
  dateFormat: "mm/dd/yy",
  onSelect: (dateText, el) ->
    to_save = $('#' + el.id).data('alt_field')
    $('#' + to_save).val($.datepicker.formatDate('yy-mm-dd', $.datepicker.parseDate('mm/dd/yy', dateText)))
  onClose: (dateText, el) ->
    try
      to_save = $('#' + el.id).data('alt_field')
      d = $.datepicker.parseDate("mm/dd/yy", dateText)
      $(this).datepicker "setDate", d
      $('#' + to_save).val($.datepicker.formatDate('yy-mm-dd', d));
    catch err # what to do if it errors, just set to date 40 years ago
      d = new Date()
      $(this).datepicker "setDate", "1-January-" + (d.getFullYear() - 40)
    return



$(document).on 'change', '.lease-structure-calc-type', ->
  dd_change_ref = this
  current_td = $(dd_change_ref).closest('td').next('td.delay_start_date_content')

  $('#dialog-message-dalay-start-date-mr input').fdatepicker(datepicker_options)
  if $(this).val() == "pass_through_and_start_date"
    $("#dialog-message-dalay-start-date-mr").dialog
      resizable: false
      modal: true
      height: 170
      width: 400
      dialogClass:'custom_dialog_style'
      buttons:
        Ok: ->
          current_date = $('#dialog-message-dalay-start-date-mr input').val()
          string_to_date_instance = new Date(current_date)
          formatted_date = $.datepicker.formatDate('yy-mm-dd', string_to_date_instance)

          $(current_td).find('span').html( current_date )
          $(current_td).find('input').val( formatted_date )
          $(this).dialog "close"
          return
  else
    $(current_td).find('span').html( "" )
    $(current_td).find('input').val( "" )


#*************************************************#


# generate additional Tenant & LL Allowances fields dynamically
$(document).on 'change', '#additional_tenant_cost_tmp, #additional_ll_cost_tmp', (e) ->
  count = parseInt( $(this).val() )

  if $(this).attr("id") == "additional_tenant_cost_tmp"
    type = "tenant"
    header = "Tenant"
  else
    type = "ll"
    header = "LL"

  $('.single-additional-cost-' + type).remove()

  i = 0
  html = ''
  if count
    while i < count
      params = { index: i+1, type: type, header: header }
      html += Mustache.render($('#additional_cost_single_template').html(), params )
      i++;
  else
    $('.single-additional-cost-' + type).remove()

  $('.lease-comp-single table tbody').append html



#*************************************************** Google addresses Api start *******************************#
placeSearch = undefined
autocomplete = undefined
autocomplete2 = undefined
autocomplete3 = undefined
componentForm =
  locality: 'long_name'
  administrative_area_level_1: 'short_name'

initAutocomplete = ->
# Create the autocomplete object, restricting the search to geographical
# location types.
  autocomplete = new (google.maps.places.Autocomplete)(document.getElementById('autocomplete'), types: [ 'geocode' ])
  autocomplete.addListener 'place_changed', ->
    fillInAddress autocomplete, ''

  autocomplete2 = new (google.maps.places.Autocomplete)(document.getElementById('autocomplete2'), types: [ 'geocode' ])
  autocomplete2.addListener 'place_changed', ->
    fillInAddress autocomplete2, '2'

  autocomplete3 = new (google.maps.places.Autocomplete)(document.getElementById('autocomplete3'), types: [ 'geocode' ])
  autocomplete3.addListener 'place_changed', ->
    fillInAddress autocomplete3, '3'

  autocomplete4 = new (google.maps.places.Autocomplete)(document.getElementById('autocomplete4'), types: [ 'geocode' ])
  autocomplete4.addListener 'place_changed', ->
    fillInAddress autocomplete4, '4'
  return

fillInAddress = (autocomplete, unique) ->
# Get the place details from the autocomplete object.
  place = autocomplete.getPlace()
  for component of componentForm
    if ! !document.getElementById(component + unique)
      document.getElementById(component + unique).value = ''
      document.getElementById(component + unique).disabled = false
  # Get each component of the address from the place details
  # and fill the corresponding field on the form.
  i = 0
  while i < place.address_components.length
    addressType = place.address_components[i].types[0]
    if componentForm[addressType] and document.getElementById(addressType + unique)
      val = place.address_components[i][componentForm[addressType]]
      document.getElementById(addressType + unique).value = val
    i++
  return

geolocate = ->
  if navigator.geolocation
    navigator.geolocation.getCurrentPosition (position) ->
      geolocation =
        lat: position.coords.latitude
        lng: position.coords.longitude
      circle = new (google.maps.Circle)(
        center: geolocation
        radius: position.coords.accuracy)
      autocomplete.setBounds circle.getBounds()
  return

window.onload = ->
  initAutocomplete()
  return

#*************************************************** Google addresses Api end *******************************#