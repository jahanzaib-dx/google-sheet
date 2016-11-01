  /*******************************
* ACCORDION WITH TOGGLE ICONS
*******************************/

$(document).ready(function(){

    $('.perfectScrollbar-wheel').perfectScrollbar({
        wheelSpeed: 20,
        wheelPropagation: false
    });


    $('#example').DataTable( {
        "scrollY": 200,
        "scrollX": true
    } );

    $('#search').on('keyup', function() {
        var pattern = $(this).val();
        $('.searchable-container .items').hide();
        $('.searchable-container .items').filter(function() {
            return $(this).text().match(new RegExp(pattern, 'i'));
        }).show();
    });

    var $active = $('#accordion .panel-collapse.in').prev().addClass('active');
    $active.find('a').prepend('<i class="glyphicon glyphicon-minus"></i>');
    $('#accordion .panel-heading').not($active).find('a').prepend('<i class="glyphicon glyphicon-plus"></i>');
    $('#accordion').on('show.bs.collapse', function (e) {
        $('#accordion .panel-heading.active').removeClass('active').find('.glyphicon').toggleClass('glyphicon-plus glyphicon-minus');
        $(e.target).prev().addClass('active').find('.glyphicon').toggleClass('glyphicon-plus glyphicon-minus');
    });

    $("#checkbox7").change(function () {
        $(".all_clicked input:checkbox").prop('checked', $(this).prop("checked"));
    });

    $("#checkbox1").change(function () {
        $("input:checkbox").prop('checked', $(this).prop("checked"));
    });

    $(".dropdown-menu li a").click(function(){
      var selText = $(this).text();
      $(this).parents('.btn-group').find('.dropdown-toggle').html(selText+' <span class="caret"></span>');

    });


    $('[data-toggle="tooltip"]').tooltip();

    $('.panel-group').on('hidden.bs.collapse', toggleIcon);
    $('.panel-group').on('shown.bs.collapse', toggleIcon);

    $(".dropdown-menu li a").click(function(){
        var selText = $(this).text();
        $(this).parents('.btn-group').find('.dropdown-toggle').html(selText+' <span class="caret"></span>');

    });

});


	function toggleIcon(e) {
        $(e.target)
            .prev('.panel-heading')
            .find(".more-less")
            .toggleClass('glyphicon-plus glyphicon-minus');
    }


  $( ".comp_type" ).click(function() {
      var cid = this.id;
      if (cid == 'comp_sales') {

          $('.resetit').val('').selectpicker('refresh');

          $(".lease_filter").css("display", "none");
          $(".lease_filter_input").prop("disabled", true);
          $(".sales_filter").css("display", "block");
          $(".sales_filter_input").prop("disabled", false);
          $(".filters_type").val("sale");
          //$(".h_filters_type").val("sale");
          $('.filters_type').selectpicker('refresh');
          $('.h_filters_type option').removeAttr('selected').filter('[value=sale]').attr('selected', true);
          $('#basic-search-form').prop('action' , search_simple_path_js)
          $('#advanced-search-form').prop('action' , search_sales_path_js)
          basic_search_url = $('#basic-search-form').prop('action');
      } else {

          $('.resetit').val('').selectpicker('refresh');

          $(".sales_filter").css("display", "none");
          $(".sales_filter_input").prop("disabled", true);
          $(".lease_filter").css("display", "block");
          $(".lease_filter_input").prop("disabled", false);
          $(".filters_type").val("lease");
          //$(".h_filters_type").val("lease");
          $('.filters_type').selectpicker('refresh');
          $('.h_filters_type option').removeAttr('selected').filter('[value=lease]').attr('selected', true);
          $('#basic-search-form').prop('action' , search_basic_path_js)
          $('#advanced-search-form').prop('action' , search_advanced_path_js)
          basic_search_url = $('#basic-search-form').prop('action');
      }
  });

  $( ".filters_type" ).change(function() {
      var fval = $(this).val();
      if (fval == 'lease') {
          $( "#comp_lease" ).click();
      } else if (fval == 'sale') {
          $( "#comp_sales" ).click();
      }
      return false;
  });

  //$('.adv_trr').click(fucntion()
  $( ".adv_trr" ).click(function() {
      $("#advanced-search-submit").click();
  });

  if ( $('.date-picker').length > 0)
  {
      $('.date-picker').datepicker({
          changeMonth: true,
          changeYear: true,
          showButtonPanel: false,
          dateFormat: 'mm/yy',
          onClose: function (dateText, inst) {
              $(this).datepicker('setDate', new Date(inst.selectedYear, inst.selectedMonth, 1));
          }
      });
  }