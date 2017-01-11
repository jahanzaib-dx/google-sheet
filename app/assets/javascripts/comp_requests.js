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
		var comptype = $btn.data("comptype");
        uiConfirm('Remove Request?','Are you sure you want to reject selected requests?', function (){
            closePopup();
            displayOverlay = true;
            var ids = [];
            jQuery('input[name^="comp_request_ids"]:checked').each(function (){
                ids.push( $(this).val() );
            });

            jQuery.post($btn.data('href'), {"ids[]": ids,"comptype":comptype}, function (json){
                if(json.status == 'success') {
					
					jQuery('input[name^="comp_request_ids"]:checked').each(function (){
						$(this).parents('tr').slideUp();
						/*ids.push( $(this).val() );*/
					});
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
    
    var selected_check_obj = $("#comprequest_page .tx_search_result_table .checkbox-info input:checkbox:checked");
    
    $("#comprequest_page .checkbox-info input:checkbox").on("click", function (){
    	selected_check_obj = $("#comprequest_page .tx_search_result_table .checkbox-info input:checkbox:checked");
    });
    
    jQuery("#comprequest_page .lock-n").on("click", function (){ 
    	/*if (!validate_transprancy()){
    		$('#Modalfull').modal('hide');
        	return false;
        }*/
    });
    
    jQuery("#comprequest_page #btn-grant-access").on("click", function (){
    	
    	
        //displayOverlay = true;
        //$('#basicModal').modal('hide');
        var $btn = jQuery(this);
        
        var selected_comp_id = selected_check_obj.val();
        $("#access_comp_id").val(selected_comp_id);
        
        if (!validate_tires()) {        	
        	return false;
        }
        
        var $form = $btn.parents('form')
        var dataString = $form.serialize();
        //console.log($form.attr('action'));
        //console.log(dataString);
        var ids = [];
        jQuery('input[name^="comp_request_ids"]:checked').each(function (){
            ids.push( $(this).val() );
        });
        
        var access = $('input[name="access"]:checked').val();        
            
        $.ajax({
            type: "POST",
            url: $form.attr('action'),
            data: {"ids[]": ids,"access":access},
            dataType: "json",
            success: function(data) {
                //console.log(data);
                if(data.status == 'success'){
                	$('#Modalfull').modal('hide');
                	selected_check_obj.attr('checked',false);
                	selected_check_obj.parents('tr').slideUp();
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
	
	function validate_transprancy(){	
		        
        if (selected_check_obj.size() > 1) {
        	// error 
        	uiAlert('Error!','Select only one comp to grant access');
        	return false;
        }
        
        if (selected_check_obj.size() < 1) {
        	// error 
        	uiAlert('Error!','Select one comp to grant access');
        	return false;
        }
		
		return true;
	}
	
	function validate_tires() {
		if ($(".tire12 input:checkbox:checked").size() < 1){
			uiAlert('Error!','Please select tire 1 or tire 2');
        	return false;
		}
		return true;
	}
	
	
	
		$('#comprequest_page .lock-p').on('click', function(){
		
		//$( ".trans_spinner" ).toggle();
		var $modal = $('#load_popup_modal_show_id');
        
        //var $selected_check_obj = $(".checkbox-info input:checkbox:checked");
        if ($(".lock-b-gray").is(":visible") ) {
        	return false;        	
        }
        if (!validate_transprancy()){
        	$('#Modalpartial').modal('hide');
        	return false;
        }
        
        $('#trans_spinner').show();
        var selected_comp_id = selected_check_obj.val();
        
		$modal.load(partial_popup_path,{'id': selected_comp_id},
			function(){
				$('#trans_spinner').hide();
				//$( ".trans_spinner" ).toggle();
				
				//$modal.modal('show');
			});
		});
		
		// ------------------------------partial transprancy---------------------------
		
		jQuery(document).on("click", '#comprequest_page .submitpartial', function (){

    	
        //displayOverlay = true;
        //$('#basicModal').modal('hide');
        var $btn = jQuery(this);
        
        var selected_comp_id = selected_check_obj.val();
        $("#partial_comp_id").val(selected_comp_id);
        
        /*if (!validate_tires()) {
        	return false;
        }*/
        
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
                	$('#Modalpartial').modal('hide');
                	selected_check_obj.attr('checked',false);
                	selected_check_obj.parents('tr').slideUp();
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
    
    
    
    // ------------------------------Activity Log---------------------------
    // ------------------------------Activity Log---------------------------
    
    
    
	jQuery(document).on("click", '.set_aid', function (){
	
		var aid = $(this).data("aid");
		$("#activity_id").val(aid);
	
	});	
	
	jQuery(document).on("click", '.change-status', function (){
	
		var a_action = $(this).data("action");
		//alert(a_action)
		$("#activity_action").val(a_action);
		
	
	});	
	
	
	jQuery(document).on("click", '#update_permission', function (){
    	
        var $btn = jQuery(this);
        
        var act_action = $("#activity_action").val();
        var act_id = $("#activity_id").val();
        //console.log($form.attr('action'));
        //console.log(dataString);
        $.ajax({
            type: "POST",
            url: act_action,
            //data: dataString,
            data: {"activity_id": act_id},
            dataType: "json",
            success: function(data) {
                //console.log(data);
                if(data.status == 'success'){
                	//$('#Modalpartial').modal('hide');
                	//selected_check_obj.attr('checked',false);
                	//selected_check_obj.parents('tr').slideUp();
                    //uiAlert('Success','Comp updated successfully!');
                    uiConfirm('Success','Comp updated successfully!', function (){ window.location.reload(true); }, function (){ window.location.reload(true); })
                    
                    
                    
                }else{
                    uiAlert('Error!','Unable to update Comp'+data.message);
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
    
    //-------------------------------------------------------------------------
    
    //-----------------------------------------------------------------------------------------------------------
    // full transprancy update
    
    var a_selected_check_obj = $("#activity_page_options #activity_id");
    
    // $(".checkbox-info input:checkbox").on("click", function (){
    	// selected_check_obj = $("#activity_id");
    // });
   
    
    jQuery("#activity_page_options #btn-grant-access").on("click", function (){
    	
    	
        //displayOverlay = true;
        //$('#basicModal').modal('hide');
        var $btn = jQuery(this);
        
        var a_selected_comp_id = a_selected_check_obj.val();
        $("#access_comp_id").val(a_selected_comp_id);
        
        if (!validate_tires()) {        	
        	return false;
        }
        
        var $form = $btn.parents('form')
        var dataString = $form.serialize();
        //console.log($form.attr('action'));
        //console.log(dataString);
        
        // var ids = [];
        // jQuery('input[name^="comp_request_ids"]:checked').each(function (){
            // ids.push( $(this).val() );
        // });
        
        var access = $('input[name="access"]:checked').val();        
            
        $.ajax({
            type: "POST",
            url: $form.attr('action'),
            data: {"id": a_selected_comp_id,"access":access},
            dataType: "json",
            success: function(data) {
                console.log(data);
                if(data.status == 'success'){
                	$('#Modalfull').modal('hide');
                	selected_check_obj.attr('checked',false);
                	selected_check_obj.parents('tr').slideUp();
                    //uiAlert('Success','Access for selected comps granted successfully');
                    uiConfirm('Success','Access for selected comps granted successfully', function (){ window.location.reload(true); }, function (){ window.location.reload(true); })
                    
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
		
	
		
		$('#activity_page_options .partail-img').on('click', function(){
		
		//$( ".trans_spinner" ).toggle();
		var $modal = $('#load_popup_modal_show_id');
        
        //var $selected_check_obj = $(".checkbox-info input:checkbox:checked");
        // if ($(".lock-b-gray").is(":visible") ) {
        	// return false;        	
        // }
        // if (!validate_transprancy()){
        	// $('#Modalpartial').modal('hide');
        	// return false;
        // }
        
        $('#activity_page_options #trans_spinner').show();
        var a_selected_comp_id = a_selected_check_obj.val();
        
		$modal.load(partial_popup_edit_path,{'id': a_selected_comp_id},
			function(){
				// $('#trans_spinner').hide();
				// //$( ".trans_spinner" ).toggle();
// 				
				// //$modal.modal('show');
			 });
		});
		
		// ------------------------------partial transprancy update---------------------------
		
		jQuery(document).on("click", '.submitpartial', function (){

    	
        //displayOverlay = true;
        //$('#basicModal').modal('hide');
        var $btn = jQuery(this);
        
        var a_selected_comp_id = a_selected_check_obj.val();
        
        //var selected_comp_id = selected_check_obj.val();
        $("#partial_id").val(a_selected_comp_id);
        
        /*if (!validate_tires()) {
        	return false;
        }*/
        
        var $form = $btn.parents('form')
        var dataString = $form.serialize();
        //console.log($form.attr('action'));
        //console.log(dataString);
        $.ajax({
            type: "POST",
            url: $form.attr('action'),
            data: dataString,
            //data: {"id":a_selected_comp_id},
            dataType: "json",
            success: function(data) {
                //console.log(data);
                if(data.status == 'success'){
                	$('#Modalpartial').modal('hide');
                	selected_check_obj.attr('checked',false);
                	selected_check_obj.parents('tr').slideUp();
                    //uiAlert('Success','Access for selected comps granted successfully');
                    uiConfirm('Success','Access for selected comps granted successfully', function (){ window.location.reload(true); }, function (){ window.location.reload(true); })
                    
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
    
    
	


});