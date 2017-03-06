#\\************************************************************\\
#   Description:
#   The dashboard javascript
#\\*************************************************************\\


$dashboard = $('#dashboard')
if ( !$dashboard.hasClass('exists') )
  return

$(document).ready () ->
  $('#advanced-search-form').trigger('submit') if $('#run_search').length > 0

summary_data = []
$body = $('body')
$body.addClass('dashboard')
$dashboard_popup = new $.Popup(
  content: $('#template_pending_search')
)
#\\************************************************************\\
#   fade alerts on dashboard away if it exists
#\\*************************************************************\\
alerts = $('.alerts')
if (alerts.length > 0)
  alerts.fadeOut(1000)

#\\************************************************************\\
#   Storing the results to display
#\\*************************************************************\\
if (typeof window.tenantrex == 'undefined')
  window.tenantrex = {}
window.results = []
window.tenantrex.elTop  = 0


#\\************************************************************\\
#   Auto Complete Events
#\\*************************************************************\\
basic_search_url = $('#basic-search-form').prop('action')

$("#autocomplete").ajaxselect(
  #url: $('#basic-search-form').prop('action')
  url: basic_search_url
  data: (term) ->
    search_type: $('input[name="tenant_record[search_type]"]:checked').val()
    term: term
    record_type: $('input[name="record_type"]:checked').val()
    #f:new Date().getTime()
).bind("change.ajaxselect", (e) ->
  $("#search").removeAttr "disabled"
  $(this).off "keydown.autocomplete"
).bind("autocompletesearch", ->
  $("#search").attr "disabled", "disabled"
  $("#address1, #zipcode").val ""
  $(this).on "keydown.autocomplete", (e) ->
    if e.keyCode is 13
      e.preventDefault()
      false
).bind("autocompleteselect", (e, ui) ->
  $("#address1").val ui.item.label.address1
  $("#zipcode").val ui.item.label.zipcode
  $("#tenant_record_property_type").val ui.item.label.property_type
).bind "focus", (e) ->
  #basic_search_url = $('#basic-search-form').prop('action')
  ##alert(basic_search_url)
  ##alert(basic_search_url)
  val = $(this).val()
  if val.indexOf(", ")
    $(this).val val.substring(0, val.indexOf(", "))
    $(this).trigger "keydown"

#\\************************************************************\\
#  Changing search type
#\\*************************************************************\\
$('input[name="tenant_record[search_type]"]').on 'change', (e) ->
  if ($(@).val() != 'address_zipcode')
    $('.extra_basic_params ul').css('opacity', '0.5')
    $('input[name="tenant_record[apply_radius]"]').prop('checked', false).prop('disabled', true)
    $('input[name="tenant_record[radius]"]').prop('disabled', true)
  else
    $('input[name="tenant_record[apply_radius]"]').removeProp('disabled')
    $('input[name="tenant_record[radius]"]').removeProp('disabled')
    $('.extra_basic_params ul').css('opacity', '')

$('input[name="tenant_record[apply_radius]"]').on 'change', (e) ->
  $('#tenant_record_latitude').val('')
  $('#tenant_record_longitude').val('')

#\\************************************************************\\
#   Basic Search
#\\*************************************************************\\
$("#basic-search-form").on "submit", (e) ->
  e.preventDefault()

  #####$adv = $('#advanced-search')
  $adv = $('#advanced-search-new')
  if ($adv.length > 0 && $adv.hasClass('active'))
    ####$($('#advanced-search .header').trigger('click'))
    $($('#advanced-search-new .header').trigger('click'))
  term = $("#autocomplete").val()
  if (term.length == 0)
    return

  $('#input[type=reset],button[type=reset]').trigger 'click',
    type: 'basic'
  disabled_tenant_records = $('input.disabled_tenant_record_id')
  if (disabled_tenant_records.length > 0)
    disabled_tenant_records.remove()

  $('#results .empty_results').addClass('searching')
  $('#autocomplete').blur()
  $('#advanced-search-form').trigger('submit')

#\\************************************************************\\
#   Clicking on the headers on the dashboard
#\\*************************************************************\\
####$dashboard.on 'click', '#advanced-search .header', (e) ->

$dashboard.on 'click', '#advanced-search-new .header', (e) ->
  e.preventDefault()

  # Empty results, don't need to show filter
  # if ($('.empty_results').length > 0)
  #   return

  #####$adv = $('#dashboard #advanced-search')
  $adv = $('#dashboard #advanced-search-new')
  $adv_form = $adv.find('form')
  if (!$adv.hasClass('active'))
    $adv.addClass('active')
    $adv_form.slideDown 'fast', () ->
      $adv_form.fadeTo 'fast', 1, () ->
        $adv_form.css('display', 'block')
  else
    $adv_form.fadeTo 'fast', 0, () ->
      $adv_form.slideUp 'fast', () ->
        $adv.removeClass('active')

#\\************************************************************\\
#   Advanced Search Reset event
#\\*************************************************************\\
#$("#advanced-search-form").on 'reset', (e, params) ->
$("input[type=reset], button[type=reset]").on 'click', (e, params) ->
  e.preventDefault() # we need to prevent the default reset now because we've allowed users to from another page
  $(@).closest('form').get(0).reset()
  if ($('input[name="q"]').val() != '')
    $('#tenant_record_latitude').val('')
    $('#tenant_record_longitude').val('')
  $('#industry_sic_code_id li').removeClass('active')
  $('#industry_sic_code_id li:first').addClass('active')
  $('#industry').val('')
  # this has to be done explicitly since we've allowed users to
  # return to a search from another page.
  $('#advanced-search-form :input').each ()->
    $(@).val("") if $(@).prop('type') == 'text'
    $(@).removeProp("checked") if $(@).prop('type') == 'checkbox'
    return
  disabled_tenant_records = $('input.disabled_tenant_record_id')
  if (disabled_tenant_records.length > 0)
    disabled_tenant_records.remove()
  if !params? or ('type' of params and params.type != 'basic')
    window.setTimeout (()-> $('#advanced-search-form').trigger('submit')), 1000

$('#advanced-search-submit').on 'click', (e) ->
  #####$('#advanced-search .header').trigger('click')
$('#advanced-search-new .header').trigger('click')

#\\************************************************************\\
#   Advanced Search Paginator
#\\*************************************************************\\
class AdvanceSearchPager
  constructor: (@page = 1) ->
    $(window).scroll(@check)

  check: =>
    if @nearBottom()
      $(window).unbind('scroll', @check)
      params = getAdvanceSearchParams('submit')
      url = params[1]
      current_page = parseInt($('#tenant_record_page').val()) + 1
      params[0].push { name: 'tenant_record[page]', value: current_page }
      $('#tenant_record_page').val(current_page)
      $dashboard_popup.open()
      $.ajax url,
        type: 'post'
        dataType: 'json',
        data: params[0],
        success: (data, ts, xhr) ->
          #remove blank row before appending
          $('.adjust_table_height').remove()
          populateResults(data, ts, xhr, true)
          new AdvanceSearchPager() if data.res.length > 0
          $dashboard_popup.close()
        error: (xhr, ts, et) ->
          $dashboard_popup.close()

  nearBottom: =>
    $(window).scrollTop() > $(document).height() - $(window).height() - 100

$ ->
  new AdvanceSearchPager()

#\\************************************************************\\
#   Advanced Search Params
#\\*************************************************************\\
getAdvanceSearchParams = (type)->
  $el = $('#advanced-search-form')
  url = $el.attr('action')
  params = $el.serializeArray()
  params = params.concat $("#advanced-search-form input[type=checkbox]:checked").map(->
    name: @name
    value: @value
  ).get()

  $q = $('input[name="q"]').val()
  if ($q.length > 0)
    params.push { name: 'tenant_record[q]', value: $q }
    params.push { name: 'tenant_record[address1]', value: $('#address1').val() }
    params.push { name: 'tenant_record[zipcode]', value: $('#zipcode').val() }
    params.push { name: 'tenant_record[search_type]', value: $('input[name="tenant_record[search_type]"]:checked').val() }
    params.push { name: 'search_type', value: $('input[name="tenant_record[search_type]"]:checked').val() }
    if $('#apply_radius:checked').length == 1
      params.push { name: 'apply_radius', value: true }
      params.push { name: 'radius', value: $('#tenant_record_radius').val() }
  params.push { name: 'trigger', value: type }
  [params, url]
#\\************************************************************\\
#   Advanced Search Submit event
#\\*************************************************************\\
$('#advanced-search-form').on 'submit different_data', (e) ->
  #reset result offset so that results are fetched from start
  $("#tenant_record_page").val(1)
  e.preventDefault()
  params = getAdvanceSearchParams(e.type)
  #$body.fadeTo('fast', 0.1)
  $dashboard_popup.open()
  $('.popup_back').css('background-color', '#FFF')
  #$('.loader_img').show()
  #####$('#advanced-search').addClass('on')
  $('#advanced-search-new').addClass('on')
  $('#results .comp_report').removeClass('hide')
  $('#results .export_results').removeClass('hide')
  $body.addClass('dashboard')
  url = params[1]
  $.ajax url,
    type: 'post'
    dataType: 'json',
    data: params[0],
    success: (data, ts, xhr) ->
      if $('#myiframe').find('iframe').length > 0
        $('#myiframe').find('iframe').attr('src','https://docs.google.com/spreadsheets/d/'+data.file+'/edit?usp=sharing');
        $('.tx_linkdin_profile').attr('href','/back_end_lease_comps/create/'+data.file);
        $('#ImageBrowse').show('slow');
        $dashboard_popup.close()
      else
        populateResults(data, ts, xhr, false)
        if data.params['tenant_record']['latitude']
          $('#tenant_record_latitude').val(data.params['tenant_record']['latitude'])

        if data.params['tenant_record']['longitude']
          $('#tenant_record_longitude').val(data.params['tenant_record']['longitude'])

        # Only on submit do we load the summary, the other trigger is different_data, and
        # we don't need the summary to the data to repopluate because it is the same
        if data.params['trigger'] and data.params['trigger'] == 'submit' and data.res
          window.setTimeout ->
            #####populateSummary(data.params)
            $dashboard_popup.close()
          , 1000
        else
          $body.fadeTo('fast', 1).addClass('search_complete')
          $dashboard_popup.close()
    error: (xhr, ts, et) ->
      #####$('#advanced-search-form').hide()
      #####$('#advanced-search').removeClass('active')
      $('#advanced-search-new').removeClass('active')
      $("#results").html $('#template_results_empty').html()
      $body.fadeTo('fast', 1)
      $dashboard_popup.close()


#\\************************************************************\\
#  Comp Report
#\\*************************************************************\\
poll_for_report = (type, p, params = {}) ->
  data = $.extend true, params, $.deparam($('#advanced-search-form').serialize()),
    $.deparam($('#basic-search-form').serialize()),
    export_type: type

  url = "search/export"

  tic = 0
  xhr = $.ajax { method: 'post', data: data, url: url }
  xhr.done (d) ->
    inv = setInterval (->
      $.post url, { filename: d.filename }, (data, status, xhr) ->
        if xhr.status == 200
          window.location.assign "#{url}?filename=#{d.filename}"
          clearInterval(inv)
          p.close()
        else
          if tic == 1000
            clearInterval(inv)
            p.close()

        tic++
    ),3000

#\\************************************************************\\
#  Description: View Comp Report PDF
#\\************************************************************\\
# For single comp
$('#results').on 'click', 'table.table thead th.comp_details .comp_detail', (e) ->
  e.preventDefault();
  return if $('#results table.table thead th.comp_details').hasClass('private') || $('#results table.table thead th.comp_details').hasClass('confidential')
  id = $(@).closest('table').data('id')
  return unless id?
  select_custom_report_template('single', id)

# For multi comp
$(document).on 'click', '#results .custom-report-multi-comp a', (e)->
  e.preventDefault();
  select_custom_report_template('multi', '')


$(document).on 'click','.dashboard-report-generate-btn', (e) ->
  e.preventDefault();
  template_id = $("input:radio[name='template-name']:checked").val()
  if template_id
    id = $("#record-to-pdf-export").val()
    if id
      popup = new $.Popup(
        content: $('#template_pending_download')
        afterOpen: () -> poll_for_report('pdf', @, { pdf_type: "single_page", pdf_id: id, template_id: template_id })
      )
    else
      popup = new $.Popup(
        content: $('#template_pending_download')
        afterOpen: () -> poll_for_report('pdf', popup, {template_id: template_id})
      )
    report_template_selection_popup = $('.dashboard-report-template-popup').bPopup()
    report_template_selection_popup.close()
    popup.open()
    $('.dashboard-report-template-popup').html '<div class="dialog"><a title="Close" class="custom-report-popup-close b-close">X</a><div class="custom-template-name-container"><h3>Please wait ...</h3></div></div>'
  else
    $.notify("error message..", "error")

#\\************************************************************\\
#   Select Export Template
#\\*************************************************************\\
select_custom_report_template = (type, record_id=null) ->
  report_template_selection_popup = $('.dashboard-report-template-popup').bPopup({
    position: ['auto', 100],
    positionStyle: 'fixed',
    escClose: false,
    modalClose: false,
    speed: 1
    })
  popup_html = ''
  $('.custom-template-name-container').empty()
  all_templates = $.ajax
    url: "/custom_reports/get_custom_templates.json",
    method: 'post',
    dataType: 'json',
    data: { template_type: type }

  all_templates.done (templates) ->
    if templates.length > 0
      popup_html = '<p class="heading">CHOOSE YOUR TEMPLATE</p><div class="custom-template-name-container-option">'
      for template in templates
        popup_html+= '<div>'+template.name+'<br><input type="radio" name="template-name" value="'+template.id+'"></div>'
      popup_html+= '</div><div class="dashboard-report-generate-btn"><a href="javascript:void(0);">Select</a></div><input type="hidden" id="record-to-pdf-export" value="'+record_id+'">'
      $('.custom-template-name-container').html popup_html
    else
      $('.custom-template-name-container').html '<p class="heading">Sorry no Template found!</p>'


#\\************************************************************\\
#  Calculate Tenant Size Range for Confidential Comps
#\\************************************************************\\

get_tenantsize_range = (size)->
  size = parseInt(size)
  if size < 2000
    range = "below 2000"
  else if size >= 2000 && size < 5000
    range = "2-5000"
  else if size >= 5000 && size < 10000
    range = "5-10,000"
  else if size >= 10000 && size < 20000
    range = "10-20,000"
  else if size >= 20000 && size < 50000
    range = "20-50,000"
  else
    range = "50,000+"

#\\************************************************************\\
#   Results Layout
#\\*************************************************************\\
$('#results').on 'click', 'table.table tbody tr td.selectable', (e) ->
  $el = $(this).parent()
  stickSidebar($el)

  # Don't do anything if clicked on already active detail
  if ($el.hasClass('active') || $el.hasClass('adjust_table_height'))
    return

  $('#results table.table tbody tr.active').removeClass('active')
  $el.delay(1000).addClass('active')

  $rex_details_header = $('#results table.table thead tr th.comp_details').removeClass('network confidential private')

  if $el.hasClass('network') || $el.hasClass('confidential')
    $rex_details_header.addClass('confidential')

  # Don't do anything if clicked on private
  if $el.hasClass('private')
    $rex_details_header.addClass('private')
    rex_detail_template = $('#template_rex_details_private').html()
    $rex = $('#rex_details')
    if ($rex.length == 0)
      $('#results .body .details_in').append(rex_detail_template)
    else
      $rex.removeClass('public confidential')
      $rex.children().remove().hide()
      r = $(rex_detail_template)
      $rex.append(r.html())
    return

  trid = $el.data('trid')
  rex = window.results[trid]
  rex['id']                 = trid
  rex['submarket']            = humanize(rex['submarket'])
  rex['company']            = humanize(rex['company'])
  rex['lease_structure']    = humanize(rex['lease_structure'])
  rex['lease_type']         = humanize(rex['lease_type'])
  rex['property_type']      = humanize(rex['property_type'])
  rex['class_type']         = humanize(rex['class_type'])
  rex['location_type']      = humanize(rex['location_type'])
  rex['net_effective_per_sf']      = (if (rex['net_effective_per_sf']) then number_format(rex['net_effective_per_sf'], 2) else 0)
  rex['size']                = get_tenantsize_range(rex['size']) if (rex['view_type'] == "confidential")
  rex['size']                = (if (rex['size'] && rex['view_type'] != "confidential" ) then number_format(rex['size']) else rex['size'])
  rex['is_stepped_rent']     = rex['is_stepped_rent']
  rex['base_rent']           = (if (rex['base_rent']) then number_format(rex['base_rent'], 2) else 0)
  rex['fs_equivalent']           = (if (rex['fs_equivalent']) then number_format(rex['fs_equivalent'], 2) else 0)
  rex['aggr_annual_rent_by_sf']  = (if (rex['aggr_annual_rent_by_sf']) then number_format(rex['aggr_annual_rent_by_sf'], 2) else 0)
  rex['tenant_improvement']  = (if (rex['tenant_improvement']) then number_format(rex['tenant_improvement'], 2) else 0)
  rex['free_rent']           = (if (rex['free_rent']) then number_format(rex['free_rent'], 0) else 0)
  if (rex['lease_commencement_date'] && rex['lease_commencement_date'].indexOf('/') == -1)
    rex['lease_commencement_date'] = moment(rex['lease_commencement_date'], 'YYYY-MM-DD').format('MM/DD/YYYY')
  if (rex['lease_expiration_date'] && rex['lease_expiration_date'].indexOf('/') == -1)
    rex['lease_expiration_date'] = moment(rex['lease_expiration_date'], 'YYYY-MM-DD').format('MM/DD/YYYY')
  if (rex['comp_type'] == 'market')
    rex['market'] = true
  if (rex['comp_type'] == 'internal')
    rex['internal'] = true

  $rex = $('#rex_details')
  if (rex['view_type'] == 'public')
    rex_details_template = $('#template_rex_details').html()
  else
    rex_details_template = $('#template_rex_details_confidential').html()

  if ($el.hasClass('adjust_table_height'))
    return # Is a placeholder for if the table row is shorter than the tenant_details, don't do anything.

  if (!trid || !window.results[trid])
    alert('Unable to retrieve data.')
    return

  render = Mustache.render(rex_details_template, rex)
  r = $(render)
  if ($rex.length == 0)
    $('#results .body .details_in').append(r)
    $('#results .body .details_in').promise().done ->
      # make sure the summary is loaded before attempting to process six sigma
      $(document).on 'summary_updated', '#results', (e) ->
        if (rex['view_type'] == 'confidential' || rex['view_type'] == 'network')
          processSixSigma('#avg_net_effective_per_sf')
        $(document).off 'summary_updated'
    processStreetView(rex)
  else
    if (rex['view_type'] != 'confidential' && rex['view_type'] != 'network')
      $rex.removeClass('confidential network')
    else if (rex['view_type'] == 'confidential')
      $rex.addClass('confidential')
    else if (rex['view_type'] == 'network')
      $rex.addClass('network')
    $rex.fadeTo 'fast', 0.1, () ->
      $rex.html(r.html())
      $(this).fadeTo 'slow', 1, () ->
        processStreetView(rex)
      $rex.promise().done ->
        if (rex['view_type'] == 'confidential' || rex['view_type'] == 'network')
          processSixSigma('#avg_net_effective_per_sf')

  $(@).closest('table').data('id', rex['id'])

#\\************************************************************\\
#   Sticky Details Bar
#\\************************************************************\\
lastScrollTop = 0
stickSidebar = (el)->
  table_first_child = $('.body tbody tr:first-child')
  if (table_first_child.length == 0)
    return
  windowScroll = $(window).scrollTop()
  topDiff = table_first_child.offset().top - windowScroll

  if topDiff > 0
    $("#rex_details").css
      top: 0
      position: "absolute"
  else
    $("#rex_details").css
      top: windowScroll - table_first_child.offset().top
      position: "absolute"

  $(window).scroll ->
    table_first_child = $('.body tbody tr:first-child')

    if (table_first_child.length == 0)
      return

    windowScroll = $(window).scrollTop()
    topDiff = table_first_child.offset().top - windowScroll

    st = $(this).scrollTop()
    if st < table_first_child.offset().top
      $("#rex_details").css
        top: 0
    else if (st <= lastScrollTop) && st <= (topDiff + $("#rex_details").position().top)
      # Scrolling up and past the top of the details bar but not too far up.
      v = st - table_first_child.offset().top
      $("#rex_details").css
        top: v
    lastScrollTop = st

#\\************************************************************\\
#   Handles sorting of the table
#\\*************************************************************\\
$('#results').on 'click', 'table.table thead tr th.address1, table.table thead tr th.company, table.table thead tr th.size, table.table thead tr th.lease_commencement_date, table.table thead tr th.net_effective_per_sf, table.table thead tr th.cushman_net_effective_per_sf', (e) ->
  e.preventDefault()
  $el = $(this)
  $el.toggleClass('desc').siblings().removeClass('desc')
  $('#tenant_record_order').val($el.prop('class'))
  $('#advanced-search-form').trigger('submit')



#\\************************************************************\\
#   Checkbox Filtering
#\\*************************************************************\\
#\\************************************************************\\
#   Displays Refresh Button if any checkbox in the th, or td
#   is selected
#\\*************************************************************\\
$('#results').on 'click', 'th input[name="tenant_record[selected]"], td input[name="tenant_record[selected]"]', (e)->
  $('.select_comps .icon').removeClass('hide')
  $('.select_comps small').addClass('hide')

#\\************************************************************\\
#   Clicks on off individual records
#\\*************************************************************\\
$('#results').on 'click', 'td.select_toggle input[name="tenant_record[selected]"]', (e)->
  $el = $(this)
  id = $el.val()
  $rec = $('tr[data-trid='+id+']')
  if ($rec.hasClass('confidential'))
    $to_set = $('#select_all_confidential_comps')
    $to_set.prop('checked', !$to_set.is(':checked') )
    $to_set = $('#tenant_record_disable_confidential_comps')
    $to_set.prop('checked', !$to_set.is(':checked'))
    $('.confidential input[type=checkbox]').each (i,v) ->
      the_input = $(v)
      if ($el.val() != the_input.val())
        the_input.prop('checked', !the_input.is(':checked'))
  else if ($rec.hasClass('private'))
    $to_set = $('#select_all_private_comps')
    $to_set.prop('checked', !$to_set.is(':checked') )
    $to_set = $('#tenant_record_disable_private_comps')
    $to_set.prop('checked', !$to_set.is(':checked'))
    $('.private input[type=checkbox]').each (i,v) ->
      the_input = $(v)
      if ($el.val() != the_input.val())
        the_input.prop('checked', !the_input.is(':checked'))
  else if ($el.is(':checked'))
    # remove the hidden field
    $('#tenant_record_disabled_tenant_record_' + id).remove()
  else
    $individual_tenant_record = $('<input>')
    .prop('id', 'tenant_record_disabled_tenant_record_' + id )
    .prop('name', 'tenant_record[disable_tenant_record_id][]')
    .prop('type', 'hidden')
    .prop('class', 'disabled_tenant_record_id')
    .prop('value', id)
    $('#advanced-search-form .hidden_fields').append($individual_tenant_record)


#\\************************************************************\\
#   Clicks on off selected records
#\\*************************************************************\\
$('#results').on 'click', 'th input[name="tenant_record[selected]"]', (e)->
  $checkboxes = $('#results td.select_toggle input[name="tenant_record[selected]"]')
  $checkboxes.map (i, check) ->
    window.setTimeout (() -> $(check).trigger('click')), 100
  $(@).prop('checked', $(@).prop('checked'))

#\\************************************************************\\
#   Refreshes results with the filter options
#\\*************************************************************\\
$('#results').on 'click', 'th.select_comps a.icon', (e) ->
  e.preventDefault()
  $('#advanced-search-form').trigger('submit')

#\\************************************************************\\
#  Display options for analytics report and select toggle filters
#\\*************************************************************\\
$('#results').on 'click', 'th.analytics_report .dropdown_click, th.select_toggle .dropdown_click', (e) ->
  e.preventDefault()
  $el = $(this)
  parent = $(this).data('parent')
  if (parent && parent.length > 0)
    $(parent).toggleClass('open')
  else
    $el.toggleClass('open')


#\\**************************************************************\\
#  Submit analytics report
##\\**************************************************************\\
$('#results').on 'click', '.analytics_report .options .create_analytics_report', (e) ->

  # get current filter (convert bools to int)
  options =
    ma_net_effective:       if $('#all_net_effective_charts').is(':checked') then true else ''
    ma_landlord_concession: if $('#landlord_net_effective_chart').is(':checked') then true else ''
    ma_landlord_effective_rent:     if $('#landlord_effective_rent_chart').is(':checked') then true else ''
    industry_comparison:    if $('#industry_comparison_industry_type').is(':checked') then true else ''
    asset_comparison:       if $('#asset_comparison_landlord_net_effective_rents').is(':checked') then true else ''

  if  !_.some(options)
    alert("At least one analytics report type must be selected")
    return false


  options.include_criteria  = if $('#supplements_include_search_criteria').is(':checked') then true else ''
  options.pdf_type = 'analytics'

  popup = new $.Popup(
    content: $('#template_pending_download')
    afterOpen: () -> poll_for_report('pdf', @, options)
  )

  popup.open()


#\\************************************************************\\
#   Refreshes results with the filter options
#\\*************************************************************\\
$('#results').on 'click', 'th.select_toggle div.options input[type=checkbox]', (e) ->
  $('.select_comps .icon').removeClass('hide')
  $('.select_comps small').addClass('hide')
  $el = $(this)
  el_id = $el.prop('id')
  if (el_id == 'select_internal_comps')
    $to_set = $('#tenant_record_disable_internal_comps')
    $to_set.prop('checked', !$to_set.is(':checked'))
  else if (el_id == 'select_market_comps')
    $to_set = $('#tenant_record_disable_market_comps')
    $to_set.prop('checked', !$to_set.is(':checked'))
  else if (el_id == 'select_all_confidential_comps')
    $to_set = $('#tenant_record_disable_confidential_comps')
    $to_set.prop('checked', !$to_set.is(':checked'))
    $to_set = $('.confidential input[type=checkbox]')
    $to_set.prop('checked', !$to_set.is(':checked'))
  else if (el_id == 'select_all_private_comps')
    $to_set = $('#tenant_record_disable_private_comps')
    $to_set.prop('checked', !$to_set.is(':checked'))
    $to_set = $('.private input[type=checkbox]')
    $to_set.prop('checked', !$to_set.is(':checked'))
  else if (el_id == 'select_network')
    $to_set = $('#tenant_record_disable_network')
    $to_set.prop('checked', !$to_set.is(':checked'))
    $to_set = $('.network input[type=checkbox]')
    $to_set.prop('checked', !$to_set.is(':checked'))

#\\************************************************************\\
#  See All Averages section,
#  Initialize average_net_effective_breakdown_graph
#\\*************************************************************\\
$('#results').on 'click close', 'th.all_averages', (e) ->
  $graph = $('#graph')
  if (e.type =='close')
    $('div.other_averages').slideUp 'fast', ()->
      $('th.all_averages').removeClass('active')
  else
    $('div.other_averages').slideToggle 'fast', ()->
      if $('th.all_averages').toggleClass('active').hasClass('active')
        if ($graph.length == 1)
          showGraph()
      else
        if ($graph.length == 1)
          $graph.children().remove()
          $('#graph_legend').children().remove()
    return false

# Attach popups to comp report and export
$('#results .export_results a').popup
  content: $('#template_excel_export')
  afterOpen: () ->
    popup = @
    $(document).off 'click', '.export-excel-btn'
    $(document).off 'change', '#export-toggle, input[name=^export_field]'

    $(document).on 'change', '#export-toggle', (e) ->
      $('input[name^=export_field]').prop('checked', $(@).is(':checked'))

    $(document).on 'change', '#export-toggle, input[name^=export_field]', (e) ->
      $btn = $('.export-excel-btn')
      if($('input[name^=export_field]:checked').length <= 0)
        $btn.addClass('disabled').attr('disabled', 'disabled')
      else
        $btn.removeClass('disabled').removeAttr('disabled')


    $(document).on 'click', '.export-excel-btn', (e) ->
      export_fields = $.map $('input[name^=export_field]'), (v) ->
        return $(v).val() if $(v).is(':checked')

      popup.close()
      wait_popup = new $.Popup(
        content: $('#template_pending_download')
        afterOpen: () -> poll_for_report('xls', wait_popup, { export_field: export_fields } )
      )
      wait_popup.open()

#\\************************************************************\\
#   Initialize future additional information buttons
#\\*************************************************************\\
$dashboard.on 'click', 'a.btn.additional_information', (e) ->
  e.preventDefault()
  section = $('section.additional_information .content').toggleClass('showing').toggle()
  return if not section.hasClass('showing')
  return if $('#additional-info-custom-fields').hasClass('updated')
  trid = $(@).data('detail_in')
  url = $(@).data('custom_fields')
  return if url is undefined or url is ""
  $.ajax url,
    dataType: 'json',
    success: (data,ts,xhr) ->
      $('#additional-info-custom-fields').addClass('updated').html(Mustache.render($('#template_additional_info_custom_fields_tmpl').html(), data))
    error: (xhr,ts, et) ->
      $('#additional-info-custom-fields').addClass('updated').html(Mustache.render($('#template_additional_info_custom_fields_tmpl').html(), {}))



#\\************************************************************\\
#  Toggle Cost Period (Month/Year)
#\\*************************************************************\\
$dashboard.on 'click', '.cost_display_toggle a', (e) ->
  e.preventDefault()
  active = $('.cost_display_toggle a.active')
  active.removeClass('active')
  cost_display = $(this).data('toggle_cost_display')
  $('#tenant_record_cost_display').val(cost_display)
  $('#advanced-search-form').trigger('submit')
  $(this).addClass('active')


#\\************************************************************\\
#   Initialize future net effective calculator buttons
#\\*************************************************************\\
$dashboard.on 'click', 'a.net_effective_calculator', (e) ->
  e.preventDefault()
  #if typeof net_effective_calculator == 'undefined'
  #  alert('Unable to initialize Net Effective Calculator')
  #  return
  #
  #net_effective_calculator.init({trid:$(this).data('trid')})
  $('#net_effective_calculator_form').trigger('submit')

$dashboard.on 'click', '#confidential_graph_select li', (e) ->
  e.preventDefault()
  $el = $(this)
  field = $el.data('value')
  processSixSigma(field)
  return


#\\************************************************************\\
#   Populates results from Basic/Advanced Search
#\\*************************************************************\\
populateResults = (data, text_status, $xhr, doAppend) ->
  #alert(data.params.record_type)
  record_type = data.params.record_type
  re = []
  is_submit = data.params.trigger and data.params.trigger == 'submit'
  $empty = $('#results .empty_results')
  if ($empty.length == 1)
    if is_submit
      $('#results').children().fadeOut 'fast', () -> $(this).remove()
      $('#results').append(Mustache.render($('#template_search_results').html()))
    else
      $empty.remove()

  if data.response && data.response.docs && data.response.docs.length > 0
    data_docs = data.response.docs
    num_recs  = data.response.docs.length
    total_count = data.response.numFound + (if(data.response.numFound > 1) then ' results' else ' result')
    count = data.response.numFound
  else if data.res && data.res.length > 0
    data_docs = data.res
    num_recs  = data.res.length
    total_count = data.count + (if(data.count > 1) then ' results' else ' result')
    count = data.count
  else
    count = 0
    if !doAppend
      $("#results .body").html $('#template_results_empty').html()
      $('#results .comp_report').addClass('hide')
      $('#results .export_results').addClass('hide')
    $body.fadeTo('fast', 1).addClass('search_complete')
    $dashboard_popup.close()
    return

  $('#results .comp_report').removeClass('hide')
  $('#results .export_results').removeClass('hide')

  # @FIX better way to indicate that the user requested to reorder table
  if (data.params.tenant_record.order == 'address1 desc')
    address_order = 'address1 desc'
  else
    address_order = 'address1'
  if (data.params.tenant_record.order == 'company desc')
    company_order = 'company desc'
  else
    company_order = 'company'
  if (data.params.tenant_record.order == 'size desc')
    size_order = 'size desc'
  else
    size_order = 'size'
  if data.params.is_cushman_user
    if (data.params.tenant_record.order == 'cushman_net_effective_per_sf desc')
      ter_order = 'cushman_net_effective_per_sf desc'
    else
      ter_order = 'cushman_net_effective_per_sf'
  else
    if (data.params.tenant_record.order == 'net_effective_per_sf desc')
      ter_order = 'net_effective_per_sf desc'
    else
      ter_order = 'net_effective_per_sf'

  if (data.params.tenant_record.order == 'lease_commencement_date desc')
    year_order = 'lease_commencement_date desc'
  else
    year_order = 'lease_commencement_date'

  filters = {}
  if (data.params.tenant_record.disable_comp_type && data.params.tenant_record.disable_comp_type.length > 0)
    for comp_type in data.params.tenant_record.disable_comp_type
      filters[comp_type] = true
  if data.params.tenant_record.disable_view_type && data.params.tenant_record.disable_view_type.length > 0
    for view_type in data.params.tenant_record.disable_view_type
      filters[view_type] = true
  if data.params.tenant_record.disable_network && data.params.tenant_record.disable_network.length > 0
    filters['network'] = true
  the_header_data =
    ordering:
      address1: address_order
      company: company_order
      size: size_order
      ter: ter_order
      lease_commencement: year_order
    filters: filters

  if !doAppend
    #$("#results .body").html Mustache.render($('#template_results_table_header').html(), the_header_data)
    $("#results .body").html Mustache.render($('#template_results_table_header_'+record_type).html(), the_header_data)
  tb = $("#results .body table tbody")
  r = ""
  found = []
  #table_template = $('#template_results_table_row').html()
  table_template = $('#template_results_table_row_'+record_type).html()
  row_count = count + 1
  re = $.map(data_docs, (item) ->

    trid = item.id
    found.push(trid)
    size = 0
    land_size_str = 0
    cap_rate_str = 0
    
    if item.view_type == 'confidential' && item.size
      size = get_tenantsize_range(item.size)
    else if item.view_type != 'confidential' && item.size
      size = number_format(item.size)
      
    if item.land_size_str
      land_size_str = item.land_size_str
    
    if item.price_str
      price_str = item.price_str
    
    if item.cap_rate_str
      cap_rate_str = item.cap_rate_str
      
    if item.user_id == current_user_id
    	requestunlock_class = ""
    	Request_Unlock_text = "N/A"
    	cpstatus = "Owner"
    else
    	requestunlock_class = "requestunlock"
    	Request_Unlock_text = "<a href='#!' >Request Unlock</a>"
    	cpstatus = "N/A"
        
    comp_img = ''
    if item.main_image_file_name == null
    	comp_img = 'http://maps.googleapis.com/maps/api/streetview?size=50x50&location='+item.address1+'+'+item.city+'+'+item.state+'+'+item.zipcode
    else
    	db_comp_img = item.main_image_file_name
    	
    	#=image("https://maps.googleapis.com/maps/api/streetview?size=350x200&location=40.7516185,-73.9419234&heading=151.78&pitch=-0.76",2)
    	
    	db_comp_img1 = db_comp_img.replace('=image("','')
    	db_comp_img2 = db_comp_img1.replace('",2)','')
    	db_comp_img3 = db_comp_img2.replace('?size=350x200&', '?size=50x50&')
    	
    	comp_img = db_comp_img3
    
    console.log (item.main_image_file_name)
    
    if item.cp_status == 'full'
    	cpstatus = "<a href='#'><img src='assets/lock-un.png'> </a>"
    	requestunlock_class = ""
    	Request_Unlock_text = "Request Sent"
    else if item.cp_status == 'partial'
    	cpstatus = "<a href='#'><img src='assets/lock-b.png'> </a>"   
    	requestunlock_class = ""
    	Request_Unlock_text = "Request Sent"
    else if item.cp_status == 'Rejected'
    	cpstatus = "<a href='#'><img src='assets/lock.png'> </a>"
    	requestunlock_class = ""
    	Request_Unlock_text = "Request Sent"
    else if item.cp_status == "Waiting"
    	cpstatus = "Waiting"
    	requestunlock_class = ""
    	Request_Unlock_text = "Request Sent"
    
    
    if size < 1
    	##size = "Lock"
    	size = item.size_range

    values =
      row_count: row_count,
      id: trid,
      company: humanize(item.company)
      address1: item.address1     
      suite: item.suite
      city: item.city
      state: item.state
      zipcode: item.zipcode
      latitude: item.latitude
      longitude: item.longitude
      size: size
      year: (if (item.lease_commencement_date) then moment(item.lease_commencement_date, 'YYYY-MM-DD').format('YYYY') else '')
      base_rent_str:item.base_rent_str
      requestunlock_class:requestunlock_class
      Request_Unlock_text:Request_Unlock_text
      cpstatus:cpstatus
      public: (item.view_type == 'public')
      view_type: item.view_type
      tef_class: if data.params.is_cushman_user then "cushman_net_effective_per_sf" else "net_effective_per_sf"
      tenant_effective_rent: if data.params.is_cushman_user then number_format(item.cushman_net_effective_per_sf, 2) else number_format(item.net_effective_per_sf, 2)
      isAppending: doAppend
      land_size_str: land_size_str
      price_str: price_str
      cap_rate_str: cap_rate_str
      comp_img: comp_img
      sold_date: (if (item.sold_date) then moment(item.sold_date, 'YYYY-MM-DD').format('YYYY') else '')
      
    r = Mustache.render(table_template, values)
    tb.append r
    
    

    # Setting to zero to allow the table height to adjust
    row_count = 0
    window.results[trid] = item
  )

  # Append a blank row, since table height might be shorter than the tenant detail's height. This row will adjust.
  tb.append(Mustache.render(table_template, {}))

  # select first result
  $('#results .body .table tbody > tr:first td').trigger('click') if $('#results .body .table tbody > tr').length > 0

  return re

#\\************************************************************\\
#   Populate the Table Summary Data
#\\*************************************************************\\
populateSummary = (params) ->
  params['tenant_record']['summary'] = true
  url = $('#advanced-search-form').attr('action')
  property_types = $('.property_types.tabs ul li a')
  selected_property_type = params['tenant_record']['property_type']
  $('#results .body').before(Mustache.render($('#template_search_results_summary').html(), {})) if ($('#results .summary').length == 0)
  $.each property_types, (tag) ->
    property_type = $(property_types[tag]).data('type')
    params['tenant_record']['property_type'] = property_type
    $.ajax url,
      type: 'post'
      dataType: 'json'
      data: params
      success: (data, ts, xhr) ->
        window.params = data.params
        showGraph()
        if (data && data.count)
          count = parseInt(data.count)
          return if !data.params['tenant_record']['property_type']
          property = data.params['tenant_record']['property_type']
          if data.count == 1
            $('.property_types.tabs ul li a[data-type='+property+'] .count').html(count)
          else
            $('.property_types.tabs ul li a[data-type=' +property+'] .count').html(count)
          summary_data[property_type] = data
          if property && property == selected_property_type[0]
            $body.fadeTo('fast', 1, () ->
              $('.property_types.tabs ul li a[data-type='+selected_property_type+']').trigger 'onlysummary'
              $(this).addClass('search_complete')
            )
    #$('.loader_img').hide()
      error: (xhr, ts, et) ->
        console.log('error', ts, et) if (typeof console != 'undefined')

costDisplay = (value, cost_display) ->
  value = 0.0 if value == undefined
  if (cost_display == 'mo')
    return value / 12.0
  return value

graphLabels = (key) ->
  return 'Base Rent' if key == 'base_rent'
  return 'Taxes' if key == 'real_estate_tax_cost'
  return 'Op. Ex.' if key == 'operator_expense_cost'
  return 'CAM' if key == 'cam_cost'
  return 'Utilities' if key == 'electrical_expense_cost'
  return 'Janitorial' if key == 'janitorial_cost'
  return 'Insurance' if key == 'insurance_cost'

graphColors = (key) ->
  return '#DC9B00' if key == 'base_rent'
  return '#333333' if key == 'real_estate_tax_cost'
  return '#444444' if key == 'operator_expense_cost'
  return '#666666' if key == 'cam_cost'
  return '#aaaaaa' if key == 'electrical_expense_cost'
  return '#cccccc' if key == 'janitorial_cost'
  return '#eeeeee' if key == 'insurance_cost'

showProperty = (summary, count, cost_display) ->
  cost_display = 'yr' if cost_display == undefined
  $('.cost_display_abbr').html(cost_display)

  if cost_display == 'yr'
    $('#cushman_market_net_effective_per_sf').html(number_format(summary.avg_cushman_market_effective, 2))
    $('#weighted_avg_annual_rent_by_sf').html(number_format(summary.weighted_avg_annual_rent_by_sf, 2))
  else
    $('#cushman_market_net_effective_per_sf').html(number_format(costDisplay(summary.avg_cushman_market_effective, cost_display), 2))
    $('#weighted_avg_annual_rent_by_sf').html(number_format(costDisplay(summary.weighted_avg_annual_rent_by_sf, cost_display), 2))

  if summary
    $.each summary, (key, value)->
      type = key.substring(0, key.indexOf('_'))
      attr = key.substring(key.indexOf('_') + 1, key.length)
      if type == 'avg' and attr == 'size'
        $('#avg_size').html(number_format(value, 0))
      else if (type == 'avg' and (attr == 'lease_term_years' or attr == 'free_rent' or attr == 'escalation'))
        $('#' + key).html(number_format(value, 1))
        .data('avg', value)
        .data('tile', summary['tile_' + attr])
        .data('field', attr)
      else if type == 'avg'
        $('#' + key).html(number_format(costDisplay(value, cost_display), 2))
        .data('avg', value)
        .data('tile', summary['tile_' + attr])
        .data('field', attr)


$dashboard.on 'click onlysummary', '.property_types.tabs ul li a', (e) ->
  e.preventDefault()
  $el = $(this)
  property_type = $el.data('type')
  active = $('.property_types.tabs ul li a.active')
  active_property_type = active.data('type')
  return if (property_type == active_property_type) and e.type == 'click'
  active.removeClass('active')
  $el.addClass('active')
  showProperty(summary_data[property_type].summary, summary_data[property_type].count, summary_data[property_type]['params']['tenant_record']['cost_display'])
  showGraph()
  if (e.type && e.type != 'onlysummary')
    $('#tenant_record_property_type').val(property_type)
    $('#advanced-search-form').trigger('different_data')
  $('#results .body').promise().done ()->
    $('#results').trigger('summary_updated')

#\\************************************************************\\
#   Allow humans to read easily the column names from db
#\\*************************************************************\\
humanize = (property) ->
  if typeof property == 'undefined' || property == null
    property
  else
    property.replace(/_/g, " ").replace /(\w+)/g, (match) ->
      match.charAt(0).toUpperCase() + match.slice(1)


processStreetView = (rex) ->
  ##if (!rex['main_image_file_name'] || rex['main_image_file_name'] == '')
    ##geocoder = new google.maps.Geocoder()
   ## geocoder.geocode { 'address': [rex['address1'],rex['city'],rex['state'],rex['zip']].join(' ') }, (results, status) ->
      ##if (status == google.maps.GeocoderStatus.OK)
        ##building = results[0].geometry.location
      ##else
        ##building = new google.maps.LatLng(rex['latitude'],rex['longitude'])
      ##options =
        ##mapTypeId: google.maps.MapTypeId.ROADMAP
        ##center: building
        ##zoom: 14
      ##window.TENANTREX.maps.findStreetView(options, document.getElementById('street_map'))

#\\************************************************************\\
#   Handles loading the correct six sigma graph
#\\*************************************************************\\
processSixSigma = (el) ->
  sixsigma = $(el)
  avg = sixsigma.data('avg')
  min = sixsigma.data('min')
  max = sixsigma.data('max')
  tile = sixsigma.data('tile')
  field = sixsigma.data('field')
  tile_data = []
  tile_data['image'] = []
  six_sigma_graph = $('#six_sigma_graph').fadeTo('fast', 0)
  six_sigma_graph.removeClass().addClass(field)
  data_url = six_sigma_graph.data('sixsigma_url')
  trid = six_sigma_graph.data('trid')
  six_sigma_graph.children().fadeOut 'fast', ()->
    $(this).remove()
  sixsigma_template = $('#template_six_sigma').html()

  if (field == 'lease_term_years' or field == 'free_rent' or field == 'escalation')
    one_value   = number_format((1*avg) - (3 * tile), 1)
    two_value   = number_format((1*avg) - (2 * tile), 1)
    three_value = number_format((1*avg) - (1 * tile), 1)
    four_value  = number_format(avg, 1)
    five_value  = number_format((1*avg) + (1 * tile), 1)
    six_value   = number_format((1*avg) + (2 * tile), 1)
    seven_value = number_format((1*avg) + (3 * tile), 1)
  else
    one_value   = '$' + number_format((1*avg) - (3 * tile), 2)
    two_value   = '$' + number_format((1*avg) - (2 * tile), 2)
    three_value = '$' + number_format((1*avg) - (1 * tile), 2)
    four_value  = '$' + number_format(avg, 2)
    five_value  = '$' + number_format((1*avg) + (1 * tile), 2)
    six_value   = '$' + number_format((1*avg) + (2 * tile), 2)
    seven_value = '$' + number_format((1*avg) + (3 * tile), 2)

  tile_data['tiles'] = [
    label: 'one'
    value: one_value
  ,
    label: 'two'
    value: two_value
  ,
    label: 'three'
    value: three_value
  ,
    label: 'four'
    value: four_value
  ,
    label: 'five'
    value: five_value
  ,
    label: 'six'
    value: six_value
  ,
    label: 'seven'
    value: seven_value
  ]

  selected_six_sigma = $('tr[data-trid='+trid+']').data(field)
  if (selected_six_sigma && selected_six_sigma.length > 1)
    if (selected_six_sigma == 'one')
      tile_data['min'] = one_value
      tile_data['max'] = two_value
    else if (selected_six_sigma == 'two')
      tile_data['min'] = two_value
      tile_data['max'] = three_value
    else if (selected_six_sigma == 'three')
      tile_data['min'] = three_value
      tile_data['max'] = four_value
    else if (selected_six_sigma == 'four')
      tile_data['min'] = four_value
      tile_data['max'] = five_value
    else if (selected_six_sigma == 'five')
      tile_data['min'] = five_value
      tile_data['max'] = six_value
    else if (selected_six_sigma == 'six')
      tile_data['min'] = six_value
      tile_data['max'] = seven_value
    tile_data['image'].push parseSixSigmaSection(selected_six_sigma)
    if field == "lease_term_years"
      tile_data['max'] = "#{tile_data['max']} yr(s)"
    if field == "free_rent"
      tile_data['max'] = "#{tile_data['max']} month(s)"
    if field == "escalation"
      tile_data['max'] = "#{tile_data['max']}%"
    six_sigma_graph.append( Mustache.render(sixsigma_template, tile_data) ).fadeTo('slow', 1)
  else
    $.ajax data_url,
      type: 'post'
      dataType: 'json'
      data:
        avg: avg
        min: min
        max: max
        tile: tile
        field: field
        id: trid
      success: (data, ts, xhr) ->
        if (data.selected_six_sigma == 'one')
          tile_data['min'] = one_value
          tile_data['max'] = two_value
        else if (data.selected_six_sigma == 'two')
          tile_data['min'] = two_value
          tile_data['max'] = three_value
        else if (data.selected_six_sigma == 'three')
          tile_data['min'] = three_value
          tile_data['max'] = four_value
        else if (data.selected_six_sigma == 'four')
          tile_data['min'] = four_value
          tile_data['max'] = five_value
        else if (data.selected_six_sigma == 'five')
          tile_data['min'] = five_value
          tile_data['max'] = six_value
        else if (data.selected_six_sigma == 'six')
          tile_data['min'] = six_value
          tile_data['max'] = seven_value
        tile_data['image'].push parseSixSigmaSection(data.selected_six_sigma)
        $('tr[data-trid='+trid+']').data(field, data.selected_six_sigma)
        if field == "lease_term_years"
          tile_data['max'] = "#{tile_data['max']} yr(s)"
        if field == "free_rent"
          tile_data['max'] = "#{tile_data['max']} month(s)"
        if data.params.field == "escalation"
          tile_data['max'] = "#{tile_data['max']}%"
        six_sigma_graph.append( Mustache.render(sixsigma_template, tile_data) ).fadeTo('slow', 1)
      error: (xhr, ts, et) ->
        six_sigma_graph.html("<h5 style='text-align: center;'><i>No value for this comp</i></h5>").fadeTo('slow', 1)
        console.log('error', ts, et) if (typeof console != 'undefined')

parseSixSigmaSection = (section) ->
  if (section == 'one')
    return one:true
  else if (section == 'two')
    return two:true
  else if (section == 'three')
    return three:true
  else if (section == 'four')
    return four:true
  else if (section == 'five')
    return five:true
  else if (section == 'six')
    return six:true
  end

showGraph =  ()->
  if params['avg_weighted_tenant_effective'].length == 0
    $('#graph').empty()
    $('#graph').append($('<span class="no-graph">Graph Not Available For The Selected Date Range</span>'))
  else
    active_property_type = $('.property_types.tabs ul li a.active').data('type')
    $('#graph').empty()
    if (summary_data[active_property_type])
      plot = $.jqplot 'graph', [summary_data[active_property_type]['params']['avg_weighted_tenant_effective']],
        title: "Market Rental Rates"
        seriesDefaults:
          renderer: $.jqplot.BarRenderer
          rendererOptions:
            fillToZero: true
          color: '#DC9B00'
          pointLabels:
            show:  true
            ypadding: 12
            formatString: '%.2f'
        axes:
          xaxis:
            renderer: $.jqplot.CategoryAxisRenderer
            ticks: summary_data[active_property_type]['params']['avg_weighted_tenant_effective_quarters']
            tickOptions:
              showGridline: false
          yaxis:
            pad: 3.05
            padMin: 0
            tickOptions:
              formatString: '$%.2f'
