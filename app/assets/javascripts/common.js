var displayOverlay = false;

jQuery(document).ready(function(){

    $('body').children().ajaxStart(function(){
        if(displayOverlay){
            $('.ajax-loading').show();
        }
    });

    $('body').children().ajaxStop(function(){
        displayOverlay = false;
        $('.ajax-loading').hide();
    });


    if($(".capitalize").length > 0){
        $(".capitalize").on("blur",function (){
            $(this).val( toTitleCase($(this).val()) );
        });
    }



});


function toTitleCase(str)
{
    return str.replace(/\w*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
}




function uiConfirm(title, message,ok_callback,cancel_callback){

    if( $("#uiConfirm").length ==0){


        var html = '<div id="uiConfirm" class="modal fade"> \
		  <div class="modal-dialog"> \
		    <div class="modal-content"> \
		      <div class="modal-header"> \
		        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button> \
		        <h4 class="modal-title">'+title+'</h4> \
		      </div> \
		      <div class="modal-body"> \
					<p>'+ message +'</p> \
		      </div> \
		      <div class="modal-footer"> \
		        <button type="button" class="btn btn-primary">OK</button> \
		        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button> \
		      </div> \
		    </div> \
		  </div> \
		</div>';

        $('body').append(html);

    }else{
        $("#uiConfirm").find('.modal-title').html(title);
        $("#uiConfirm").find('.modal-body p').html(message);

        $('#uiConfirm .btn-primary').unbind();
        $('#uiConfirm .btn-default').unbind();
    }

    $('#uiConfirm .btn-primary').on('click', function(e) {
        e.preventDefault();
        ok_callback();
    });

    if(typeof cancel_callback == "function"){
        $('#uiConfirm .btn-default').on('click', function(e) {
            e.preventDefault();
            cancel_callback();
        });
    }

    $("#uiConfirm").modal();
}

function uiLoader(title, message){
    if(message == ''){ message = 'Please wait...';}
    if(title == ''){ title = 'Loading...'; }
    if( $("#uiLoader").length ==0){
        var html = '<div id="uiLoader" class="modal fade"> \
		  <div class="modal-dialog"> \
		    <div class="modal-content"> \
		      <div class="modal-header"> \
		        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button> \
		        <h4 class="modal-title">'+title+'</h4> \
		      </div> \
		      <div class="modal-body"> \
			    <p>'+ message +'</p> \
			    <p><img src="/images/long-loading.gif" /></p> \
		      </div> \
		    </div> \
		  </div> \
		</div>';

        $('body').append(html);

    }else{
        $("#uiLoader").find('.modal-title').html(title);
        $("#uiLoader").find('.modal-body p:first').html(message);
    }

    $("#uiLoader").modal();
}

function clearLoader(){
    if($("#uiLoader").length > 0){
        if($("#uiLoader").is(":visible")) {
            $("#uiLoader").modal("hide");
            return;
        }
    }
}

function uiAlert(title, message){

    if( $("#uiAlert").length ==0){

        var html = '<div id="uiAlert" class="modal fade"> \
		  <div class="modal-dialog"> \
		    <div class="modal-content"> \
		      <div class="modal-header"> \
		        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button> \
		        <h4 class="modal-title">'+title+'</h4> \
		      </div> \
		      <div class="modal-body"> \
			    <p>'+ message +'</p> \
		      </div> \
		      <div class="modal-footer"> \
		        <button type="button" class="btn btn-primary">OK</button> \
		      </div> \
		    </div> \
		  </div> \
		</div>';

        $('body').append(html);

    }else{
        $("#uiAlert").find('.modal-title').html(title);
        $("#uiAlert").find('.modal-body p').html(message);
    }

    $('#uiAlert .btn-primary').on('click', function(e) {
        e.preventDefault();
        $("#uiAlert").modal("hide");
    });

    $("#uiAlert").modal();
}

function closePopup()
{
    if($("#uiPrompt .btn-default").length > 0){
        //$("#uiPrompt .btn-cancel").trigger("click");
        $("#uiPrompt").modal("hide");
        return;
    }

    if($("#uiConfirm .btn-default").length > 0){
        //$("#uiConfirm .btn-cancel").trigger("click");
        $("#uiConfirm").modal("hide");
        return;
    }

    if($("#uiPopup .btn-default").length > 0){
        $("#uiPopup").modal("hide");
        return;
    }


    if($("#externalSiteWrapper").length > 0){
        $("#externalSiteWrapper").modal("hide");
        return;
    }

}

