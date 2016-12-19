jQuery("document").ready(function (){

    jQuery(".tx_hand_right a").on("click", function (){
        displayOverlay = true;
        jQuery.post( jQuery(this).data('href'), {id: jQuery(this).data('request-id')}, function (json){
            if(json.status == 'success'){
                uiAlert('Success','Reminder sent for selected comp');
            }
        }, 'json');
        return false;
    });

    jQuery(".btn-comp-request-status").on("click", function (){
        jQuery(".btn-comp-request-status").parents('li').removeClass("active-locl");
        jQuery(".btn-comp-request-status").removeClass("selected");
        jQuery(this).parent('li').addClass("active-locl");
        jQuery(this).addClass("selected");
    });


    jQuery("#btn-decline-comp-request").on("click", function (){
        var $btn = jQuery(this);
        uiConfirm('Remove Request?','Are you sure you want to reject selected requests?', function (){
            closePopup();
            displayOverlay = true;
            var ids = [];
            jQuery('input[name^="comp_request_ids"]:checked').each(function (){
                ids.push( $(this).val() );
            });

            jQuery.post($btn.data('href'), {"ids[]": ids}, function (json){
                if(json.status == 'success') {
                    $btn.parents('tr').slideUp();
                    uiAlert('Success', 'Request removed');
                }

            },'json');

        });

        return false;
    });


    jQuery("#btn-accept-comp-request").on("click", function (){
        var $btn = jQuery(this);
        uiConfirm('Grant Access?','Are you sure you want to grant access to selected comps?', function (){
            closePopup();
            displayOverlay = true;
            var ids = [];
            jQuery('input[name^="comp_request_ids"]:checked').each(function (){
                ids.push( $(this).val() );
            });

            var access = '';
            jQuery(".btn-comp-request-status").each(function (){
               if($(this).hasClass('selected')){
                   access = $(this).data('status');
               }
            });
            console.log(access);
            jQuery.post($btn.data('href'), {"ids[]": ids, "access": access }, function (json){
                if(json.status == 'success') {
                    $btn.parents('tr').slideUp();
                    uiAlert('Success', 'Access for selected comps granted successfully');
                }

            },'json');

        });

        return false;
    });
    
    //-----------------------------------------------------------------------------------------------------------
    
    // full transprancy
    jQuery("#btn-grant-access").on("click", function (){
    	$('#Modalfull').modal('hide');
        displayOverlay = true;
        //$('#basicModal').modal('hide');
        var $btn = jQuery(this);
        
        var $selected_check_obj = $(".checkbox-info input:checkbox:checked")
        
        if ($selected_check_obj.size() > 1) {
        	// error 
        	uiAlert('Error!','Select only one comp to grant access');
        	return;
        }
        
        if ($selected_check_obj.size() < 1) {
        	// error 
        	uiAlert('Error!','Select one comp to grant access');
        	return;
        }
        
        var selected_comp_id = $selected_check_obj.val();
        $("#access_comp_id").val(selected_comp_id);
        
        
        var $form = $btn.parents('form')
        var dataString = $form.serialize();
        //console.log($form.attr('action'));
        //console.log(dataString);
        $.ajax({
            type: "POST",
            url: $form.attr('action'),
            data: dataString,
            dataType: "json",
            success: function(data) {
                //console.log(data);
                if(data.status == 'success'){
                	$selected_check_obj.parents('tr').slideUp();
                    uiAlert('Success','Access for selected comps granted successfully');
                    
                }else{
                    uiAlert('Error!','Unable to grant access. '+data.message);
                    // if(data.issue == 'Mobile Validation'){
                        // document.location.href = data.url;
                    // }else {
                        // $('#basicModal').modal('show');
                    // }
                }
            }
        });

        return false;
    });
    
    $(function(){
	    $("input:checkbox.chkfull").click(function(){
	      $("input:checkbox.chkfull").not($(this)).removeAttr("checked");
	      $(this).attr("checked", $(this).attr("checked"));    
	    });
	});
	
	$(function(){
	    $("#checkbox1,.checkbox-info input:checkbox").click(function(){
	    	var checked_check = $(".checkbox-info input:checkbox:checked").size();
	    	
	    	if (checked_check > 1) {
	    		$(".active_trans").hide();
	    		$(".inactive_trans").show();
	    		$(".active_trans").parents('li').removeClass("active-locl");
	    	} else {
	    		$(".active_trans").show();
	    		$(".inactive_trans").hide();
	    	}
	    	
	    });
	});
	
	$(function(){
	    $(".tx_lock_list li").click(function(e){	    	
	      $(".inactive_trans").parents('li.active-locl').removeClass("active-locl");  
	    });
	});


});