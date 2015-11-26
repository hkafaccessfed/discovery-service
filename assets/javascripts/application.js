//= require jquery
//= require semantic-ui
//= require datatables/jquery.dataTables
//= require slimscroll/jquery.slimscroll

$(document).ready(function () {

  function initScroller() {
    $('#scroller').slimScroll({
      height: '250px',
      wheelStep: 40,
      alwaysVisible: true
    });
  }

  function makeMessagesClosable() {
    $('.message .close').on('click', function () {
      $(this).closest('.message').transition('fade');
    });
  }

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
      if (tr.attr('role') == 'row') {
        if (tr.hasClass('active')) {
          tr.removeClass('active');
        }
        else {
          unselectIdP();
          tr.addClass('active');
        }
      }
    });
  }

  function displayErrorMessage(header, text) {
    if ($('#error_message').is(":hidden")) {
      $('#error_message').transition('fade');
    }
    $('#error_message_header').text(header);
    $('#error_message_text').text(text);
  }

  function appendIdPSelectionOnFormSubmit() {
    $("#idp_selection_form").submit(function () {
      var selectedIdPRowSelector = "#idp_selection_table tbody tr.active td"
          + " input.select_organisation_input";
      var selectedIdP = $(selectedIdPRowSelector).attr('name');

      if (selectedIdP) {
        $('<input />').attr('type', 'hidden')
            .attr('name', 'user_idp')
            .attr('value', selectedIdP)
            .appendTo('#idp_selection_form');
        return true;

      } else {
        displayErrorMessage('Error',
            'You must select your organisation to continue');
        return false;
      }
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
    unselectIdP();
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

  function showTabs() {
    $('#tab_menu').css('height', '100%');
  }

  function setFirstTabAsActive() {
    $('#tab_menu .item').removeClass('active');
    $('#tab_menu .item:first').addClass('active');
  }

  function getSP(spJson, initiatingSP) {
    for (i = 0; i < spJson.length; i++) {
      if (spJson[i].entity_id == initiatingSP) {
        return spJson[i];
      }
    }
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
      $('#sp_header_name').text(sp.name);
      if (sp.description) {
        $('#sp_header_description').text(sp.description);
      }
      if (sp.logo_url) {
        $('#sp_header_logo').attr("src", sp.logo_url);
      }
      if (sp.information_url) {
        $('#sp_header_information_url').attr("href", sp.information_url);
        $('#sp_header_information_url').text('Service Information');
      }
      if (sp.privacy_statement_url) {
        $('#sp_header_privacy_statement_url').
            attr("href", sp.privacy_statement_url);
        $('#sp_header_privacy_statement_url').text('Privacy Statement');
      }
    }
  }

  function setCursorToPointerOnIdPRows() {
    $('#idp_selection_table tbody tr').css('cursor', 'pointer');
  }

  function hideButtonsAlongsideEachIdP() {
    $('.select_organisation_input').hide();
  }

  function renderLogo(logoURL) {
    if (logoURL) {
      return '<img class="ui image tiny bordered" src="' + logoURL + '">';
    } else {
      return '';
    }
  }

  function renderIdPDetails(idPDetails) {
    var details = '<strong>' + idPDetails.name + '</strong><br/>';
    if (idPDetails.description) {
      details += '<em>' + idPDetails.description + '</em>';
    }
    return details;
  }

  function renderEntityIdInput(entityID) {
    return '<input class="select_organisation_input" name="' + entityID + '"' +
        ' type="submit">';
  }

  function buildDataset(idPData) {
    return idPData.map(function (idP) {
      var idPDetails = {}
      idPDetails.name = idP.name;
      idPDetails.description = idP.description;
      return [idPDetails, idP.logo_url, idP.entity_id, idP.tags];
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
        {render: renderIdPDetails, targets: 0},
        {render: renderLogo, targets: 1},
        {render: renderEntityIdInput, targets: 2},
        {visible: false, targets: 3}
      ],
      aoColumns: [
        {"bSearchable": true},
        {"bSearchable": false},
        {"bSearchable": false},
        {"bSearchable": true}
      ],
      order: [[0, 'asc']],
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
      setCursorToPointerOnIdPRows();
    });
  }

  function performSearchOnIdPSearchKeyup() {
    $('#search_input').keyup(function () {
      $('#idp_selection_table').DataTable().search($(this).val()).draw();
    })
  }

  function preventEnterKey() {
    $(window).keydown(function (event) {
      if (event.keyCode == 13) {
        event.preventDefault();
        return false;
      }
    });
  }

  function initHandlers() {
    preventEnterKey();
    makeTabsClickable();
    makeIdPRowsSelectable();
    appendIdPSelectionOnFormSubmit();
    submitFormOnSelectIdPButtonClick();
    clearSearchOnClearButtonClick();
    locateIdPsOnLocateButtonClick();
    performSearchOnIdPSearchKeyup();
    makeMessagesClosable();

  }

  function showJSEnabledElements() {
    showTabs();
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
    initScroller();
    setCursorToPointerOnIdPRows();
  }

  init();

});
