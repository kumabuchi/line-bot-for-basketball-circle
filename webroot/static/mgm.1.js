
$('.mdl-button--icon').on('click', function() {
  if(!$(".ok-button").length || $(".check-button").length || $(".merge-button").length) { return; }
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

$('.check-button').on('click', function() {
  if ($('input[name="src"]').val() == "" || $('input[name="dest"]').val() == "") {
    alert("マージ元もしくはマージ先を認識できません。お手数ですが再入力してください( *´艸｀)");
    return false;
  }
  if ($('input[name="src"]').val() == $('input[name="dest"]').val()) {
    alert("マージ元とマージ先が同じです。お手数ですが再入力してください( *´艸｀)");
    return false;
  }
  $("#submit-form").attr('action', location.href);
  $("#submit-button").click();
});

$('.merge-button').on('click', function() {
  if(window.confirm('この操作はやり直せませんのでご注意ください。マージを実行しますか？')){
    $("#submit-form").attr('action', location.href);
    $("#submit-button").click();
  }
});

$('#src > li').on('click', function(e) {
  var text  = $(e.target).text();
  var value = $(e.target).val();
  $('input[name="src"]').val(value);
  $(e.target).parents('.mdl-select').addClass('is-dirty').children('input').val(text);
  location.href="#top";
});
$('#dest > li').on('click', function(e) {
  var text = $(e.target).text();
  var value = $(e.target).val();
  $('input[name="dest"]').val(value);
  $(e.target).parents('.mdl-select').addClass('is-dirty').children('input').val(text);
  location.href="#top";
});
