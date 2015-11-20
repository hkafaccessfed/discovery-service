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
          + " input.select_organisation_input";
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
    $('#idp_selection_table tbody tr').css('cursor', 'pointer');
  }

  function hideButtonsAlongsideEachIdP() {
    $('.select_organisation_input').hide();
  }

  function renderLogo(logoURI) {
    return '<img class="ui image tiny bordered" src="' + logoURI + '">';
  }

  function renderIdPDetails(idPDetails) {
    return '<strong>' + idPDetails.name + '</strong><br><em>' +
        idPDetails.description + '</em><br>' + idPDetails.domain;
  }

  function renderEntityIdInput(entityID) {
    return '<input class="select_organisation_input" name="' + entityID + '">';
  }

  function buildDataset(idPData) {
    return idPData.map(function (idP) {
      var idPDetails = {}
      idPDetails.name = idP.name;
      idPDetails.description = idP.description;
      idPDetails.domain = idP.domain;
      return [idP.logo_uri, idPDetails, idP.entity_id];
    });
  }

  function loadDataTable() {
    var idpJson = $.parseJSON($('#idps').html());

    $('#idp_selection_table').DataTable({
      data: buildDataset(idpJson),
      scrollCollapse: true,
      paging: false,
      sDom: '<"top">rt<"bottom"><"clear">',
      columnDefs: [
        { render: renderLogo, targets: 0 },
        { render: renderIdPDetails, targets: 1 },
        { render: renderEntityIdInput, targets: 2 }
      ],
      bAutoWidth: false
    });
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
    loadInitiatingSPDetails();
  }

  function init() {
    showJSEnabledElements();

    initHandlers();
    loadDataTable();
    hideButtonsAlongsideEachIdP();
    setCursorToPointerOnIdPRows();
  }

  init();

});
