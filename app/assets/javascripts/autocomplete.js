$.fn.ajaxselect = function(options) {
    var settings = {
        delay: 300,
        data: function(term) {
            return {term:term};
        },
        url: '',
        select: function(item) {

        },
        html: true,
        minLength: 1,
        autoSelect: true
    };
    if(options) {
      $.extend(settings, options);
    }
    var ac_instance = $(this).autocomplete({
      source: function(request, response) {
          var re;
          var data = settings.data.call(this.element[0], request.term);
          $.ajax({
              url: settings.url,
              dataType: 'json',
              data: data,
              success: function(data, textStatus, $xhr) {
                if (typeof data.response == 'undefined' || typeof data.response.docs == 'undefined'){
                  response([]);
                } else {
                  var parse_array = [];
                  var search_type = $('input[name="tenant_record[search_type]"]:checked');
                  re = $.map(data.response.docs, function(item) {
                    var lc_address = item.address1.toLowerCase();
                    var label_is = item
                    var value_is = item.address1 + ', ' + item.zipcode;
                    if (search_type.length > 0) {
                      var search_is = search_type.val();
                      if (search_is == 'company'){
                        lc_address = item.company.toLowerCase();
                        value_is = item.company;
                      } else if (search_is == 'submarket'){
                        lc_address = item.submarket.toLowerCase();
                        value_is = item.submarket;
                      } else if (search_is == 'property_name'){
                        lc_address = item.property_name.toLowerCase();
                        value_is = item.property_name;
                      }
                    }
                    if (!(lc_address in parse_array)) {
                      parse_array[lc_address] = "";
                      return {
                        label: label_is,
                        value: value_is
                      };
                    }
                  });
                  response(re);
                }
              },
              error: function($xhr, textStatus) {
                response([]);
              }
          });
        },
        focus: function(event, ui) {
            return false;
        },
        search: function(event, ui) {
            $(this).data('lastSearch', this.value);
        },
        select: function(event, ui) {
            if($(this).val() === $(this).data('lastSearch')) {
                if(settings.select.call(this, ui.item) !== false) {
                    $(this).val(ui.item.value);
                }
                $(this).data('selectedValue',$(this).val()).trigger('change');
            }
            return false;
        },
        minLength: settings.minLength,
        autoFocus: settings.autoSelect,
        delay: settings.delay,
        html: settings.html
    }).bind('change.ajaxselect', function() {
      $(this).toggleClass('selected', $(this).val() === $(this).data('selectedValue'));
    }).data('ui-autocomplete');

    ac_instance._renderItem = function(ul,item){
      var addr_info = item.label;
      var search_type = $('input[name="tenant_record[search_type]"]:checked');
      var $span = $('<span>').addClass('address-extra').text(addr_info.city + ', ' + addr_info.state + ' ' + addr_info.zipcode);
      var text_is = addr_info.address1;
      if (search_type.length > 0) {
        search_is = search_type.val();
        if (search_is == 'company') {
          text_is = addr_info.company;
          $span = "";
        }
        if (search_is == 'property_name') {
          text_is = addr_info.property_name;
          $span = "";
        }
        if (search_is == 'submarket') {
          text_is = addr_info.submarket;
          $span = "";
        }
      }
      return $("<li>")
        .attr("data-value", item.value)
        .append($("<a>").text(text_is).append($span))
        .appendTo(ul);
    };

    if(settings.autoSelect) {
        $(this).bind('autocompletechange', function(event, ui) {
            if($(this).val() !== $(this).data('selectedValue') && this.value.length > 0) {
                var self = this;
                var data = $.extend({autoSelect:1},settings.data.call(this, this.value));
                $(this).addClass('.ui-autocomplete-loading');
                $.ajax({
                    url: settings.url,
                    dataType: 'json',
                    data: data,
                    success: function(data, textStatus, $xhr) {
                        if(data.length >= 1) {
                            var item = $.ui.autocomplete.prototype._normalize(data)[0];
                            if(settings.select.call(self, item) !== false) {
                                $(self).val(item.value);
                            }
                            $(self).data('selectedValue',$(self).val()).trigger('change');
                        }
                    },
                    complete: function($xhr, textStatus) {
                        $(self).removeClass('.ui-autocomplete-loading');
                    }
                });
            }
        });
    }

    if(!settings.minLength) {
        $(this).bind('focus.ajaxselect', function() {
            if(!$(this).autocomplete('widget').is(':visible')) {
                $(this).autocomplete('search','');
            }
        });
    }

    return $(this);
};

