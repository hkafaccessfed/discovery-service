//= require jquery
//= require semantic-ui
//= require datatables/jquery.dataTables
//= require slimscroll/jquery.slimscroll

$(document).ready(function () {

  function setHandlers() {
    $('#search_clear_button').on('click', function () {
      clearSearch();
    });
    $('#organisations_near_me_button').on('click', function () {
      getLocation();
    });
  }

  function hideNonJSElements() {
    $('.select_organisation_button').hide();
  }

  function showJSEnabledElements() {
    $('#search_options').show();
    $('#select_organisation_button').css( "display", "inline-block")
    $('#select_organisation_button').text('Select');

  }

  function init() {
    hideNonJSElements();
    showJSEnabledElements();

    setHandlers();
  }

  init();

});
