$(document).ready(function() {

  function basketUncheckAll(update) {
    $(".basket").each( 
      function(index) {
       $(this).attr('checked',false);
      }
    );
  }

  function backetCheckAll(update) {
    $(".basket").each( 
      function(index) {
       $(this).attr('checked',true);

       if (update) {
         var recid = $(this).attr('value');
         $.post('/basket/add' , { id: recid });
       }
      }
    );
  }

  function basketUpdateAll() {
     $.getJSON('/basket/list', function(data) {
        $(".basket").each(
          function(index) {
            var recid = $(this).attr('value');
            if (data[recid] == 1) {
                $(this).attr('checked',true);
            }
          }  
        );
     });
  }
  
  $(".basket").change(function(event) {
     var checked = $(this).is(':checked');
     var recid   = $(this).attr('value');
     
     if (checked) {
       $.post('/basket/add' , { id: recid });
     }
     else {
       $.post('/basket/delete' , { id: recid });
     }
  });

  $(".basketclear").click(function(event) {
       $.post('/basket/clear');
       basketUncheckAll(false);
  });

  $(".basketall").click(function(event) {
    basketCheckAll(true);
  });


  basketUpdateAll();
});
