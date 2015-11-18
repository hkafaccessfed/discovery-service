//= require jquery
//= require semantic-ui
//= require datatables/jquery.dataTables
//= require slimscroll/jquery.slimscroll

$(document).ready(function () {

  function makeIdPRowsSelectable() {
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
  }

  function appendIdPSelectionOnFormSubmit() {
    $("#idp_selection_form").submit(function () {
      var selectedIdPRowSelector = "#idp_selection_table tbody tr.active td"
          + " input.select_organisation_button";
      var selectedIdP = $(selectedIdPRowSelector).attr('name');
      // TODO validation here

      $('<input />').attr('type', 'hidden')
          .attr('name', selectedIdP)
          .appendTo('#idp_selection_form');
      return true;
    });
  }

  function showSearchOptions() {
    $('#search_options').show();
  }

  function submitFormOnSelectIdPButtonClick() {
    $('#select_organisation_button').on('click', function () {
      $("#idp_selection_form").submit();
    });
  }

  function clearSearchOnClearButtonClick() {
    $('#search_clear_button').on('click', function () {
      // TODO
    });
  }

  function locateOrganisationsOnLocateButtonClick() {
    $('#organisations_near_me_button').on('click', function () {
      // TODO
    });
  }

  function displayMainIdPSelectButton() {
    $('#select_organisation_button').css("display", "inline-block");
    $('#select_organisation_button').text('Select');
  }

  function loadInitiatingSPDetails() {
    $('#sp_header').text('');             // TODO Set Initiating SP
    $('#sp_header_logo').attr("src", ''); // TODO Set Initiating SP
    $('#sp_header_logo').hide();          // TODO TEMP
  }

  function setCursorToPointerOnIdPRows() {
    $('.datatable tbody tr').css('cursor', 'pointer');
  }

  function hideNonJSElements() {
    // Hide buttons alongside each IdP (for HTML only)
    $('.select_organisation_button').hide();
  }

  function initHandlers() {
    makeIdPRowsSelectable();
    appendIdPSelectionOnFormSubmit();
    submitFormOnSelectIdPButtonClick();
    clearSearchOnClearButtonClick();
    locateOrganisationsOnLocateButtonClick();
  }

  function showJSEnabledElements() {
    showSearchOptions();
    displayMainIdPSelectButton();
    setCursorToPointerOnIdPRows();
    loadInitiatingSPDetails();
  }

  function init() {
    hideNonJSElements();
    showJSEnabledElements();

    initHandlers();
  }

  init();

});
