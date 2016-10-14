#\\************************************************************\\
#   Drop down
#\\*************************************************************\\
$('body').on 'click', '.dropdown-wrapper .dropdown_click, .dropdown-select-wrapper .dropdown_click', (e) ->
  e.preventDefault()
  $el = $(this)
  parent = $(this).data('parent')
  if (parent && parent.length > 0)
    $(parent).toggleClass('open')
  else
    $el.parent().toggleClass('open')

#\\************************************************************\\
#   Drop down select
#\\*************************************************************\\
$('body').on 'click', '.dropdown li', (e) ->
  $el = $(this)
  $el_parent = $el.parent()
  $hidden_field = $('#' + $el.data('hidden_id')).val($el.data('value'))
  $el.addClass('active').siblings().removeClass('active')

