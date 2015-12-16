//= require jquery
//= require semantic-ui
//= require datatables/jquery.dataTables
//= require slimscroll/jquery.slimscroll
//= require jquery-cookie

function enableHelpLink() {
  $('#help_link').show();
  $('#help_link').on('click', function () {
    $('.ui.modal').modal().modal('show');
  });
}

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

function disableSelectOrganisationButton() {
  $('#select_organisation_button').addClass('disabled');
}

function enableSelectOrganisationButton() {
  $('#select_organisation_button').removeClass('disabled');
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
        disableSelectOrganisationButton();
      }
      else {
        unselectIdP();
        tr.addClass('active');
        enableSelectOrganisationButton();
      }
    }
  });
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
  disableSelectOrganisationButton();
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

function displayMainIdPSelectButton() {
  $('#select_organisation_button').addClass('disabled');
  $('#select_organisation_button').css("display", "inline-block");
  $('#select_organisation_button').text('Continue to your organisation');
}

function enableTabs() {
  $('#tab_content').css('padding-top', '0');
  if ($('#tab_menu').children().length > 0) {
    $('#tab_menu').css('height', '100%');
    setFirstTabAsActive();
    $.fn.dataTable.ext.search.push(
        function (settings, data) {
          var tagsForIdP = data[3];
          var selectedTab = $('#tab_menu a.active').attr('data-tab');
          return tagsForIdP.indexOf(selectedTab) != -1 || selectedTab == '*'
        }
    );
  }
}

function setFirstTabAsActive() {
  $('#tab_menu .item').removeClass('active');
  $('#tab_menu .item:first').addClass('active');
}

function getSP(spJson, initiatingSP) {
  for (var i = 0; i < spJson.length; i++) {
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

  for (var i = 0; i < sURLVariables.length; i++) {
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
    $('.sp_header_name').text(sp.name);

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

function renderIdPDetails(idPName) {
  return '<strong>' + idPName + '</strong><br/>';
}

function renderEntityIdInput(entityID) {
  return '<input class="select_organisation_input" name="' + entityID + '"' +
      ' type="submit">';
}

function idPGrouping(entityId) {
  for (var i = 0; i < recentOrganisations.length; i++) {
    if (recentOrganisations[i] == entityId) {
      return 'Recent'
    }
  }
  return 'Others';
}

function getGroupName() {
  var pathAsArray = window.location.pathname.split('/');
  var groupName = pathAsArray[pathAsArray.indexOf("discovery") + 1];
  return groupName;
}

function filterActiveIdPs(userOrganisationsForGroup) {
  var recentOrganisations = [];

  for (var i = 0; i < idpJson.length; i++) {
    if (userOrganisationsForGroup.indexOf(idpJson[i].entity_id) != -1) {
      recentOrganisations.push(idpJson[i].entity_id);
    }
  }
  return recentOrganisations;
}

function getRecentOrganisations() {
  var recentOrganisationsCookie = $.cookie("recent_organisations");
  if (recentOrganisationsCookie) {
    var groupName = getGroupName();
    var recentOrganisationsJson = JSON.parse(recentOrganisationsCookie);
    if (groupName in recentOrganisationsJson) {
      return filterActiveIdPs(recentOrganisationsJson[groupName]);
    }
  }
  return [];
}

function buildDataset() {
  var groupedIdPs = idpJson.map(function (idP) {
    var group = idPGrouping(idP.entity_id);
    return [idP.name, idP.logo_url, idP.entity_id, idP.tags, group];
  });

  return groupedIdPs.sort(function (a, b) {
    var groupA = a[4];
    var groupB = b[4];
    var nameA = a[0];
    var nameB = b[0];

    if (groupA == groupB) {
      return nameA.localeCompare(nameB);
    } else {
      return groupB.localeCompare(groupA);
    }
  });
}

function appendHeaders(settings) {
  if (recentOrganisations.length > 0) {
    var api = this.api();
    var rows = api.rows({page: 'current'}).nodes();
    var last = null;

    api.column(4, {page: 'current'}).data().each(function (group, i) {
      if (group == 'Others' && last !== group &&
          $('#search_input').val().trim() == "") {
        $(rows).eq(i).before(
            '<tr class="group"><td colspan="3"><div class="sub header">' +
            '</div></td></tr>'
        );
        last = group;
      }
    });
  }
}

function loadDataTable() {
  $('#idp_selection_table').DataTable({
    data: buildDataset(),
    scrollCollapse: true,
    paging: false,
    sDom: '<"top">rt<"bottom"><"clear">',
    columnDefs: [
      {sClass: "idp_selection_table_name_column", targets: 0},
      {render: renderIdPDetails, targets: 0},
      {sClass: "idp_selection_logo_column", targets: 1},
      {render: renderLogo, targets: 1},
      {render: renderEntityIdInput, targets: 2},
      {visible: false, targets: 3},
      {visible: false, targets: 4}
    ],
    aoColumns: [
      {"bSearchable": true},
      {"bSearchable": false},
      {"bSearchable": false},
      {"bSearchable": true},
      {"bSearchable": false},
    ],
    bSort: false,
    bAutoWidth: false,
    drawCallback: appendHeaders
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
  performSearchOnIdPSearchKeyup();
  makeMessagesClosable();
}

function showJSEnabledElements() {
  enableTabs();
  showSearchOptions();
  displayMainIdPSelectButton();
  loadInitiatingSPDetails();
  initialiseCheckbox();
  focusSearchField();
  enableHelpLink();
}

function initGroupPage() {
  idpJson = $.parseJSON($('#idps').html());
  recentOrganisations = getRecentOrganisations();

  showJSEnabledElements();

  initHandlers();
  loadDataTable();

  hideButtonsAlongsideEachIdP();
  initScroller();
  setCursorToPointerOnIdPRows();
}

