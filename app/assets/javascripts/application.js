// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.

//= require jquery_ujs
//= require bootstrap.min
//= require common
//= require jquery.mousewheel
//= require perfect-scrollbar
//= require jquery.dataTables.min
//= require bootstrap-select.min
//= require custom
//= require connections
//= require messages
//= require comp_requests
//= require autocomplete
//= require jqueryuicustom.min
//= require bpopup
//= require jquery.popup
//= require moment
//= require moment-timepicker
//= require date-time-picker
//= require number_format
//= require mustache
//= require dashboard
//= require map
//= require jquery.validate.min.js
//= require dropdown_t
//= require search
//= require_self

jQuery(document).ready(function () {

    jQuery("#activity_select, #messages_select, #connections_select ").on("change", function () {

        var val = jQuery(this).val();
        jQuery(this).children("option").each(function () {
            if (jQuery(this).attr('value') == val) {
                document.location.href = jQuery(this).data('href');
            }
        });

    });

});