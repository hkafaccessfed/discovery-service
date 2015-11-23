//= require jquery
//= require semantic-ui
//= require datatables/jquery.dataTables
//= require slimscroll/jquery.slimscroll

$(document).ready(function () {

  function focusSearchField() {
    $("#search_input").focus();
  }

  function initialiseCheckbox() {
    $('.ui.checkbox').checkbox();
  }

  function unselectIdP() {
    $('#idp_selection_table tbody tr').removeClass('active');
  }

  function makeIdPRowsSelectable() {
    $('#idp_selection_table tbody').on('click', 'tr', function () {
      var tr = $(this);
      if (tr.hasClass('active')) {
        tr.removeClass('active');
      }
      else {
        unselectIdP();
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

  function clearSearch() {
    $('#search_input').val('');
    $('#idp_selection_table').DataTable()
        .search('')
        .columns().search('')
        .draw();
  }

  function clearSearchOnClearButtonClick() {
    $('#search_clear_button').on('click', function () {
      clearSearch();
    });
  }

  function locateIdPsOnLocateButtonClick() {
    $('#organisations_near_me_button').on('click', function () {
      // TODO
    });
  }

  function displayMainIdPSelectButton() {
    $('#select_organisation_button').css("display", "inline-block");
    $('#select_organisation_button').text('Select');
  }

  function showTabItems() {
    $('#tab_menu a').show();
  }

  function setFirstTabAsActive() {
    $('#tab_menu .item:first').addClass('active');
  }

  function getSP(spJson, initiatingSP) {
    for (i = 0; i < spJson.length; i++) {
      if (spJson[i].entity_id == initiatingSP) {
        return spJson[i];
      }
    }
  }

  function renderSPHeader(sp) {
    return 'Login to "<em>' + sp.name + '</em>"';
  }

  function getUrlParameter(sParam) {
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
        sURLVariables = sPageURL.split('&'),
        sParameterName,
        i;

    for (i = 0; i < sURLVariables.length; i++) {
      sParameterName = sURLVariables[i].split('=');

      if (sParameterName[0] === sParam) {
        return sParameterName[1] === undefined ? true : sParameterName[1];
      }
    }
  }

  function loadInitiatingSPDetails() {
    var spJson = $.parseJSON($('#sps').html());
    var initiatingSP = getUrlParameter('entityID');

    if (initiatingSP) {
      var sp = getSP(spJson, initiatingSP);
      $('#sp_header').html(renderSPHeader(sp));
      $('#sp_header_description').text(sp.description);
      $('#sp_header_logo').attr("src", sp.logo_uri);
      $('#sp_header_information_url').attr("href", sp.information_uri);
      $('#sp_header_privacy_statement_uri').
          attr("href", sp.privacy_statement_uri);
    }
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
      return [idP.logo_uri, idPDetails, idP.entity_id, idP.tags];
    });
  }

  $.fn.dataTable.ext.search.push(
      function (settings, data) {
        var tagsForIdP = data[3];
        var selectedTab = $('#tab_menu a.active').attr('data-tab');
        return tagsForIdP.indexOf(selectedTab) != -1 || selectedTab == '*'
      }
  );

  function loadDataTable() {
    var idpJson = $.parseJSON($('#idps').html());

    $('#idp_selection_table').DataTable({
      data: buildDataset(idpJson),
      scrollCollapse: true,
      paging: false,
      sDom: '<"top">rt<"bottom"><"clear">',
      columnDefs: [
        {render: renderLogo, targets: 0},
        {render: renderIdPDetails, targets: 1},
        {render: renderEntityIdInput, targets: 2},
        {visible: false, targets: 3}
      ],
      bAutoWidth: false
    });
  }

  function makeTabsClickable() {
    $('#tab_menu .item').on('click', function () {
      $('#tab_menu .item').removeClass('active');
      $(this).addClass('active');
      $('#idp_selection_table').DataTable().draw();
      clearSearch();
      unselectIdP();
    });
  }

  function performSearchOnIdPSearchKeyup() {
    $('#search_input').keyup(function () {
      $('#idp_selection_table').DataTable().search($(this).val()).draw();
    })
  }

  function initHandlers() {
    makeTabsClickable();

    makeIdPRowsSelectable();
    appendIdPSelectionOnFormSubmit();
    submitFormOnSelectIdPButtonClick();
    clearSearchOnClearButtonClick();
    locateIdPsOnLocateButtonClick();
    performSearchOnIdPSearchKeyup();

  }

  function showJSEnabledElements() {
    showTabItems();
    setFirstTabAsActive();
    showSearchOptions();
    displayMainIdPSelectButton();
    loadInitiatingSPDetails();
    initialiseCheckbox();
    focusSearchField();
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
