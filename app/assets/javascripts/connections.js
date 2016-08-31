jQuery(document).ready(function (){

    jQuery("#connection_requests_list .accpt_btn").on('click', function (){
       displayOverlay = true;
       var $btn = jQuery(this);
        //console.log($btn.data('request-id'));
       jQuery.post($btn.data('href'),{request_id: $btn.data('request-id')}, function (json){
           if(json.status == 'success'){
               $btn.parents('tr').slideUp();
               uiAlert('Success', 'Connection request approved');
           }else{
               uiAlert('Error', 'Unable to approve connection request');
           }
       },'json');
       return false;
    });

    jQuery("#connection_requests_list .ignore_btn").on('click', function (){

        var $btn = jQuery(this);
        uiConfirm('Cancel Request?','Are you sure you want to cancel connection request?', function (){
            closePopup();
            displayOverlay = true;
            $.ajax({
                url: $btn.data('href'),
                type: 'DELETE',
                success: function(result) {
                    $btn.parents('tr').slideUp();
                    uiAlert('Success', 'Connection request Ignored');
                }
            });
        });

        return false;
    });


    jQuery("#connections_list .ignore_btn").on('click', function (){

        var $btn = jQuery(this);
        uiConfirm('Remove Connection?','Are you sure you want to remove this connection?', function (){
            closePopup();
            displayOverlay = true;
            $.ajax({
                url: $btn.data('href'),
                type: 'DELETE',
                success: function(result) {
                    $btn.parents('tr').slideUp();
                    uiAlert('Success', 'Connection removed');
                }
            });
        });

        return false;
    });

});