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

    $('#txt-area').keypress(function (e) {
        var key = e.which;
        if(key == 13)  // the enter key code
        {
            $('#btn-connection-invite').click();
        }
    });

    jQuery("#btn-connection-invite").on("click", function (){
        displayOverlay = true;
        $('#basicModal').modal('hide');
        var $btn = jQuery(this);
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
                console.log(data);
                if(data.status == 'success'){
                    uiAlert('Success','Connection request successfully sent to the user');
                }else{
                    uiAlert('Error!','Unable to send connection request. '+data.message);
                    if(data.issue == 'Mobile Validation'){
                        document.location.href = data.url;
                    }else {
                        $('#basicModal').modal('show');
                    }
                }
            }
        });

        return false;
    });


    jQuery("#group_id").on("change", function (){
        var gp_id = jQuery(this).val();
        if(gp_id.trim() != "") {
            url = jQuery(this).parent("form").attr("action");
            url = url.replace("@", gp_id);
            document.location.href = url;
        }
    });

});