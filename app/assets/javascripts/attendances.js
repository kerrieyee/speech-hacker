$(document).ready(function() {
  show_hide_role_sign_up();
  hide_role_id();
  hide_alert_boxes();

  var old_user_id;

  $('.attendance-role-select').focus(function() {
    old_user_id = $(this).val();
  }).change(function() {
    user_id = $(this).val();
    role_id = $(this).parent().parent().find('.role-title-id').html();
    meeting_id = $('#meeting_id').val();

    var params = "old_user_id=" + old_user_id + "&user_id=" + user_id + "&role_id=" + role_id;

    $.ajax({
      type: 'post',
      url:  '/meetings/' + meeting_id + '/attendances',
      dataType: 'json',
      data: params,
        success: function(data, status, xhr) {
          console.log("ajax success");
        },
        error: function(xhr, status, error) {
          console.log("ajax error");
        }
    }); // ajax
  });

  // Show role options if the user selects to attend the meeting
  $('.attend-option').on('click', function(e) {
    if ($(this).val() == 'true') {
      $('.role-sign-up').fadeIn('fast');
    } else {
      $('.role-sign-up').fadeOut('fast');
    }
  });

  // Show speech options when the speaker role is selected
  $('.role-option').on('click', function(e) {
    if ($(this).val() == $('.Speaker-option').val())
      $('.speech-fields').fadeIn('fast');
    else
      $('.speech-fields').fadeOut('fast');
  });

  // Change project options when the selected manual is changed
  $('.manual-select').change(function(){
    var params = "manual_id="+$(this).val();

    $.ajax({
      type: 'get',
      url:  '/manuals/' + $(this).val() + '/projects/',
      dataType: 'json',
      data: params,
        success: function(data, status, xhr) {
          console.log("ajax success");
          replace_projects(data["projects"]);
        },
        error: function(xhr, status, error) {

        }
    }); // ajax
  });

  function replace_projects(projects) {
    var $select_elem = $(".project-select");
    $select_elem.empty(); // remove old options
    for (var i = 0; i < projects.length; i++) {
      $select_elem.append($("<option></option>")
         .attr("value", projects[i].id).text(projects[i].name));
    }
  }

  function show_hide_role_sign_up() {
    if ($('#attendance_attend_true').attr('checked')) {
      $('.role-sign-up').show();
    } else if ($('#attendance_attend_false').attr('checked')){
      $('.role-sign-up').hide();
    }

    if ($('.Speaker-option').attr('checked')) {
      $('.speech-fields').show();
    } else {
      $('.speech-fields').hide();
    }
  }

  function hide_alert_boxes() {
    $('.notice-box').hide();
    $('.alert-box').hide();
  }

  function hide_role_id() {
    $('.role-title-id').hide();
  }
});