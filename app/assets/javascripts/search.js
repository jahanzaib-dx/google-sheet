$(document).ready(function() {
    $('.show-hide-div').attr('style', 'display: none !important');
    $('.show-hide-div2').attr('style', 'display: block !important');
    $('.show-hide-div4').attr('style', 'display: none !important');
    $('.show-hide-div3').attr('style', 'display: block !important');
    $('#checkboxes3').attr('style','display: none !important');

});

$(function() {

    //alert($.fn.ajaxselect);

    //console.log( $.fn.ajaxselect({ url: $('#basic-search-form').prop('action') }) );
    //console.log( $.fn.ajaxselect(url) )
    //console.log($( "body" ).data());

  $( ".comp_type" ).click(function() {
    var cid = this.id;
    if (cid == 'comp_sales') {

     $('#checkboxes4').attr('style','display: none !important');
     $('#checkboxes2').attr('style','display: none !important');
     $('.resetit').val('').selectpicker('refresh');
     $('.show-hide-div2').attr('style','display: none !important');
     $('.show-hide-div').attr('style','display: block !important');
     $('.show-hide-div3').attr('style','display: none !important');
     $('.show-hide-div4').attr('style','display: block !important');

      /////$(".lease_filter").css("display", "none");
      $('.lease_filter').attr('style','display: none !important');
      $(".lease_filter_input").prop("disabled", true);
      /////$(".sales_filter").css("display", "block");
      $('.sales_filter').attr('style','display: block !important');
      $(".sales_filter_input").prop("disabled", false);
      $(".filters_type").val("sale");
      $(".h_filters_type").val("sale");
      $('.filters_type').selectpicker('refresh');
      ////$('.h_filters_type option').removeAttr('selected').filter('[value=sale]').attr('selected', true);
      $('#basic-search-form').prop('action' , search_simple_path_js)
      $('#advanced-search-form').prop('action' , search_sales_path_js)
      basic_search_url = $('#basic-search-form').prop('action');
    } else {

      $('.resetit').val('').selectpicker('refresh');
      $('.show-hide-div2').attr('style','display: block !important');
      $('.show-hide-div').attr('style','display: none !important');
      $('.show-hide-div4').attr('style','display: none !important');
      $('.show-hide-div3').attr('style','display: block !important');

      ////$(".sales_filter").css("display", "none");
      $('.sales_filter').attr('style','display: none !important');

      $(".sales_filter_input").prop("disabled", true);
      ////$(".lease_filter").css("display", "block");
      $('.lease_filter').attr('style','display: block !important');


      $(".lease_filter_input").prop("disabled", false);
      $(".filters_type").val("lease");
      $(".h_filters_type").val("lease");
      $('.filters_type').selectpicker('refresh');
      ////$('.h_filters_type option').removeAttr('selected').filter('[value=lease]').attr('selected', true);
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

  });

  // $(function() {
    // $('.date-picker').datepicker( {
      // changeMonth: true,
      // changeYear: true,
      // showButtonPanel: false,
      // dateFormat: 'mm/yy',
      // onClose: function(dateText, inst) {
        // $(this).datepicker('setDate', new Date(inst.selectedYear, inst.selectedMonth, 1));
      // }
    // });
  // });

  $( document ).on( "click", ".markspam", function() {
    spamurl = $(this).data("url");

	if (spamurl != "") {
		$(this).addClass("disabled");

		$.ajax({
		  type: "GET",
		  url: spamurl
		});
	}

	$(this).removeClass("active");
	$(this).data("url","");

  });

    $( document ).on( "click", ".requestunlock", function() {

	var unobj = $(this);
	createRequesturl = unobj.data("url");

	if (createRequesturl != "") {
		/*$(this).addClass("disabled");*/

		$.ajax({
		  type: "POST",
		  url: createRequesturl
		}).done(function( msg ) {
		  /*alert( unobj.data("url") );*/
		  unobj.removeClass("requestunlock");
		  unobj.html("Request Sent");
		});
	}

	/*$(this).removeClass("active");*/
	/*$(this).data("url","");*/

  });

   $( document ).on( "click", ".clear-btn", function() {
		$('.resetit').val('').selectpicker('refresh');
  });





