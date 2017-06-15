
$('.mdl-button--icon').on('click', function() {
  if(!$(".ok-button").length) { return; }
  $(this).siblings().removeClass("mdl-button--accent");
  $(this).siblings().removeClass("mdl-button--backgroundcolor-accent");
  $(this).addClass('mdl-button--accent');
  $(this).addClass('mdl-button--backgroundcolor-accent');
});

$('.ok-button').on('click', function() {
  if ($('.button-group').length != $(".mdl-button--icon.mdl-button--accent").length) {
    alert("未入力の日程があります！\n全日程を入力して下さい( *´艸｀)")
    return false;
  }
  $(".mdl-button--icon.mdl-button--accent").each(function(i, e) {
    $("#submit-form").append('<input type="hidden" name="'+e.name+'" value="'+e.value+'"/>');
  });
  $("#submit-form").attr('action', location.href);
  $("#submit-button").click();
});
