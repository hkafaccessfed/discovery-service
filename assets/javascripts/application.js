//= require jquery
//= require semantic-ui
//= require datatables/jquery.dataTables
//= require slimscroll/jquery.slimscroll

$(document).ready(function () {

  function initHandlers() {

    // Make rows on the IdP table selectable
    $('#idp_selection_table tbody').on('click', 'tr', function () {
      var tr = $(this);
      if (tr.hasClass('active')) {
        tr.removeClass('active');
      }
      else {
        $('#idp_selection_table tbody tr').removeClass('active');
        tr.addClass('active');
      }
    });

    $('#search_clear_button').on('click', function () {
      // TODO clearSearch();
    });

    $('#organisations_near_me_button').on('click', function () {
      // TODO getLocation();
    });
  }

  function hideNonJSElements() {
    // Hide buttons alongside each IdP (for HTML only)
    $('.select_organisation_button').hide();
  }

  function showJSEnabledElements() {
    // Search only works when JS enabled, so show it
    $('#search_options').show();

    // Display the main "Select" button below the IdP list
    $('#select_organisation_button').css("display", "inline-block");
    $('#select_organisation_button').text('Select');

    // We only want the pointer icon to appear on IdP rows when JS enabled
    $('.datatable tbody tr').css('cursor', 'pointer');

    $('#sp_header').text('');             // TODO Set Initiating SP
    $('#sp_header_logo').attr("src", ''); // TODO Set Initiating SP
    $('#sp_header_logo').hide();          // TODO TEMP
  }

  function init() {
    hideNonJSElements();
    showJSEnabledElements();

    initHandlers();
  }

  init();

});
