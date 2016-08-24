  /*******************************
* ACCORDION WITH TOGGLE ICONS
*******************************/

$(document).ready(function(){
		$('.perfectScrollbar-wheel').perfectScrollbar({
		  wheelSpeed: 20,
		 wheelPropagation: false
		});
		});

$(document).ready(function() {
    $('#example').DataTable( {
        "scrollY": 200,
        "scrollX": true
    } );
} );




jQuery(function ($) {
    var $active = $('#accordion .panel-collapse.in').prev().addClass('active');
    $active.find('a').prepend('<i class="glyphicon glyphicon-minus"></i>');
    $('#accordion .panel-heading').not($active).find('a').prepend('<i class="glyphicon glyphicon-plus"></i>');
    $('#accordion').on('show.bs.collapse', function (e) {
        $('#accordion .panel-heading.active').removeClass('active').find('.glyphicon').toggleClass('glyphicon-plus glyphicon-minus');
        $(e.target).prev().addClass('active').find('.glyphicon').toggleClass('glyphicon-plus glyphicon-minus');
    })
});

$(document).ready(function(){
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
});


	function toggleIcon(e) {
        $(e.target)
            .prev('.panel-heading')
            .find(".more-less")
            .toggleClass('glyphicon-plus glyphicon-minus');
    }
    $('.panel-group').on('hidden.bs.collapse', toggleIcon);
    $('.panel-group').on('shown.bs.collapse', toggleIcon);


$(document).ready(function(){
    $('[data-toggle="tooltip"]').tooltip();   
});
$(".dropdown-menu li a").click(function(){
  var selText = $(this).text();
  $(this).parents('.btn-group').find('.dropdown-toggle').html(selText+' <span class="caret"></span>');
  
});