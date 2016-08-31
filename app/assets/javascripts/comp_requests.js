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


});