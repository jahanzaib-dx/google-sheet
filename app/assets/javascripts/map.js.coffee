$dashboard = $('#dashboard')
if ( !$dashboard.hasClass('exists') )
  return

if (typeof window.tenantrex == 'undefined')
  window.tenantrex = {}

window.deleted_map_search = []

window.tenantrex.center = [-76.6167, 39.2833]
$user_office_lat = $('#template_map_display').data('latitude')
$user_office_lng = $('#template_map_display').data('longitude')
if ($user_office_lat && $user_office_lng)
  window.tenantrex.center = [$user_office_lng, $user_office_lat]

#\\************************************************************\\
#   User defined maps - need to populate what came from the server
#\\************************************************************\\
window.user_defined_maps = null
$user_defined_map_url = $('#template_map_display').data('user_defined_maps_url')
if (typeof $user_defined_map_url != 'undefined')
  $.ajax $user_defined_map_url,
    type: 'get'
    dataType: 'json'
    success: (data, ts, xhr) ->
      window.user_defined_maps = data
    complete:
      if (window.user_defined_maps == null)
        window.user_defined_maps = []

#\\************************************************************\\
#   Geography Filtering
#\\*************************************************************\\
$('#tenant_record_zipcode_or_city_value').on 'keypress', () ->
  if ($(this).val().length > 0)
    $('#autocomplete').val('').attr('disabled', true)
    $('#apply_radius').attr('checked', false).attr('disabled', true)
    $('#radius').attr('disabled', true)
    $('#tenant_record_latitude').val('')
    $('#tenant_record_longitude').val('')
    $('#tenant_record_map_mode').val('')
  else
    $('#autocomplete').removeAttr('disabled')
    $('#apply_radius').removeAttr('disabled')
    $('#radius').removeAttr('disabled')

$('#tenant_record_zipcode_or_city_value').on 'blur', () ->
  if ($(this).val().length == 0)
    $('#autocomplete').removeAttr('disabled')
    $('#apply_radius').removeAttr('disabled')
    $('#radius').removeAttr('disabled')
  $('#tenant_record_latitude').val('')
  $('#tenant_record_longitude').val('')
  $('#tenant_record_map_mode').val('')



applyRadius = (lat, long) ->

  latitude = [lat]
  longitude = [long]
  d = $('#tenant_record_radius').val() / 1.60934
  # in miles, 6371km is the earths radius
  R =  3959
  # Bearing
  brngs = [0, 90, 180, 270]
  for b in brngs
    brng = toRad(b)
    lat1 = toRad(lat)
    lon1 = toRad(long)
    lat2 = Math.asin(Math.sin(lat1) * Math.cos(d/R) + Math.cos(lat1) * Math.sin(d/R) * Math.cos(brng));
    lon2 = lon1 + Math.atan2(Math.sin(brng) * Math.sin(d/R) * Math.cos(lat1), Math.cos(d/R) - Math.sin(lat1) * Math.sin(lat2));
    lon2 = (lon2 + 3 * Math.PI) % (2 * Math.PI) - Math.PI
    lat2 = toDeg(lat2)
    lon2 = toDeg(lon2)
    latitude.push(lat2)
    longitude.push(lon2)

  if (latitude.length > 0 && longitude.length > 0)
    $('#tenant_record_latitude').val(latitude.join(','))
    $('#tenant_record_longitude').val(longitude.join(','))


toRad = (v) ->
  return v * Math.PI / 180

toDeg = (v) ->
  return v * 180 / Math.PI

#\\************************************************************\\
#   Change Drawing Style
#\\*************************************************************\\
$('body').on 'click', '#map_controls li.mode', (e) ->
  e.preventDefault()
  advance_search_map.setOptions({draggable: false})
  $el = $(this)
  mode = $el.data('mode')
  advance_search_map.setOptions({draggable: mode == 'pan'})


  # toggle instructions
#  $('#instructions > p').hide()
#  $("#instructions > p##{mode}-instructions").show()

#\\************************************************************\\
#   Zooming In/Out
#\\*************************************************************\\
$('body').on 'click', '.btn.zoom', (e) ->
  e.preventDefault()
  $el = $(this)
  current_zoom = advance_search_map.getZoom()
  if ($el.hasClass('zoom-out'))
    advance_search_map.setZoom(current_zoom - 1)
  else if ($el.hasClass('zoom-in'))
    advance_search_map.setZoom(current_zoom + 1)


#\\************************************************************\\
#   Result and Center Map
#\\*************************************************************\\
$('body').on 'click', '.popup .center-map', (e) ->
  e.preventDefault()
  latlng = new google.maps.LatLng(window.tenantrex.center[1], window.tenantrex.center[0])
  advance_search_map.setCenter(latlng)
  advance_search_map.setZoom(11)

#\\************************************************************\\
#   Submit the Map to Advanced Search
#\\*************************************************************\\
$('body').on 'click', '.popup .use_map', (e) ->
  e.preventDefault()
  data =
    id: Math.round(new Date().getTime() / 1000)
    latitude: $('#tenant_record_latitude').val()
    longitude: $('#tenant_record_longitude').val()
    mode: $('#map').data('mode')
    name: $('#map_name').val()

  save_map = $('#save_map').is(':checked')
  if (save_map)
    $('#saved_maps .user_defined_maps .empty').remove()
    the_url = $('#map').data('add_url')
    if (the_url.length > 0)
      $.ajax the_url,
        type: 'put',
        dataType: 'json'
        data:
          map: data
        success:(data, ts, xhr) ->
          for map, i in window.user_defined_maps
            compare = "" + map.id
            if compare == data.old_id
              window.user_defined_maps[i].id = data.new_id
        error: (xhr, ts, et) ->
          #console.log('error', ts, et)

    if (typeof window.user_defined_maps != 'undefined')
      window.user_defined_maps.push data

  if (data.latitude != '' && data.longitude != '')
    $('#advanced-search-form').trigger('submit')
  $map_popup.close()

#\\************************************************************\\
#   Delete the saved map
#\\*************************************************************\\
$('body').on 'click', '#saved-map-select li.coordinate .delete', (e) ->
  e.preventDefault()

  $el = $('#' + $(this).data('coordinate_id'))
  the_url = $('#map').data('delete_url')
  if (the_url.length > 0)
    $.ajax the_url,
      type: 'delete',
      dataType: 'json'
      data:
        id: $el.data('id')
      success:(data, ts, xhr) ->
        $('.coordinate_'+ data.deleted_id).remove()
        deleted_map_search.push(data.deleted_id)
        old_list = window.user_defined_maps
        new_list = old_list
        for map, i in old_list
          compare = "" + map.id
          if compare == data.deleted_id
            new_list = old_list.slice(0,i).concat( old_list.slice(i+1) )
        window.user_defined_maps = new_list

      error: (xhr, ts, et) ->
        console.log('error', ts, et)


#\\************************************************************\\
#   Use the saved maps
#\\*************************************************************\\
$('body').on 'click', '#saved-map-select li.coordinate .map_name', (e) ->
  e.preventDefault()
  $el = $('#' + $(this).data('coordinate_id'))
  map = $('#map')
  mode = $el.data('mode')
  latitude = $el.data('latitude')
  longitude = $el.data('longitude')
  coordinates = []
  center = window.tenantrex.center
  if (latitude && longitude && latitude.length > 0 && longitude.length > 0)
    $('#tenant_record_latitude').val(latitude)
    $('#tenant_record_longitude').val(longitude)
    $('#tenant_record_map_mode').val(mode)

  if typeof latitude == 'string' && typeof longitude == 'string'
    latitude = latitude.split(',')
    longitude = longitude.split(',')
    i = 0
    len = latitude.length
    while i < len
      coordinates.push new google.maps.LatLng(latitude[i], longitude[i])
      i++
    center = new google.maps.LatLng(parseFloat(latitude[0]), parseFloat(longitude[0]))
  else
    center = new google.maps.LatLng(parseFloat(latitude), parseFloat(longitude))

  advance_search_map.setOptions({center: center, zoom: 11})
  polygon = new google.maps.Polygon(
    paths: coordinates
    strokeColor: "#FF0000"
    fillColor: "#FF0000"
  )
  polygon.setMap(advance_search_map);
  $('#saved-map-select').removeClass('open')




#\\************************************************************\\
#   Close Map Popup
#\\*************************************************************\\
$('body').on 'click', '.popup .close', (e) ->
  e.preventDefault()
  $map_popup.close()

#\\************************************************************\\
#   Toggle Map Display
#\\*************************************************************\\
$map_popup = null
$('.advanced_map_search').popup
  width: 700
  height: 450
  closeContent: ''
  content:$('#map_filter')
  afterClose: () ->
    $('#autocomplete').removeAttr('disabled')
    $('#apply_radius').removeAttr('disabled')
    $('#radius').removeAttr('disabled')
    $('#the_map').slideUp 'fast', () ->
      $('.geography_criteria .options').slideDown('fast')
      $(this).children().remove()
  afterOpen: () ->
    $map_popup = this
    map = null
    $('#autocomplete').val('').attr('disabled', true)
    $('#apply_radius').attr('checked', false).attr('disabled', true)
    $('#radius').attr('disabled', true)

    the_map = $('.popup #the_map')
    if (window.user_defined_maps.length != 0)
      $map_template = Mustache.render($('#template_map_display').html(), { user_defined_maps: window.user_defined_maps })
    else
      $map_template = Mustache.render($('#template_map_display').html(), { })

    the_map.append($map_template)
    if typeof deleted_map_search != 'undefined'
      for deleted_ele in deleted_map_search
        the_map.find('.coordinate_' + deleted_ele).remove()

    the_map.fadeIn 'fast', () ->
      mapOptions =
        draggable: false
        zoom: 11
        center: new google.maps.LatLng( window.tenantrex.center[1], window.tenantrex.center[0])

      map = new google.maps.Map(document.getElementById("map"), mapOptions)
      drawingManager = new google.maps.drawing.DrawingManager(
        drawingMode: google.maps.drawing.OverlayType.POLYGON
        drawingControl: false
      )
      drawingManager.setMap map
      window.advance_search_map = map
      google.maps.event.addListener drawingManager, "polygoncomplete", (polygon) ->
        coordinates = polygon.getPath().getArray()
        i = 0
        len = 0
        latitude = []
        longitude = []
        p = null
        if (typeof coordinates != 'undefined' && coordinates.length > 0)
          len = coordinates.length
          if (typeof len != 'undefined')
            while (i < len)
              p = coordinates[i]
              longitude.push(p.lng())
              latitude.push(p.lat())
              i++

          if (latitude.length > 0 && longitude.length > 0)
            $('#tenant_record_latitude').val(latitude.join(','))
            $('#tenant_record_longitude').val(longitude.join(','))
            $('#tenant_record_map_mode').val('Polygon')
            $('#map').data('mode', 'Polygon')
        return

      # Reset the latitude and longitude values
      $('#tenant_record_latitude').val('')
      $('#tenant_record_longitude').val('')
      $('#tenant_record_map_mode').val('')

