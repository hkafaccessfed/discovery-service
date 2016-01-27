var e = function(name, id) {
  var el = document.createElement(name);
  if (id) { el.setAttribute('id', id) }
  return el;
};

var aaf_logo =
  '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' +
  'AElFTkSuQmCC';

var wayf_div = e('div', 'wayf_div');
wayf_div.style =
  'background: ' + wayf_background_color + ';' +
  'border: 1px solid ' + wayf_border_color + ';' +
  'width: auto;' +
  'height: auto;' +
  'padding: 10px;' +
  'text-align: left' +
  'overflow: hidden';

if (typeof(wayf_width) === 'number') {
  wayf_div.style.width = wayf_width + 'px';
}
if (typeof(wayf_height) === 'number') {
  wayf_div.style.height = wayf_height + 'px';
}

var logo_div = e('div', 'wayf_logo_div')
logo_div.style = 'float: right;';

var logo_link = e('a', null);
logo_link.style = 'border: 0px;';
logo_link.href = 'http://www.aaf.edu.au';

var logo = e('img', 'wayf_logo');
logo.src = 'data:image/png;base64,' + aaf_logo;
logo.width = 103;
logo.height = 25;

var label = e('label', 'wayf_intro_label');
label.innerText = 'Login with:';
label.style = 'float: left; min-width: 80px;' +
  'font-size: ' + wayf_font_size + 'px;' +
  'color: ' + wayf_font_color;

var form = e('form', 'IdPList');
form.method = 'get';
form.action = wayf_sp_samlDSURL;

var hidden_samlds = e('input');
hidden_samlds.name = 'SAMLDS';
hidden_samlds.value = '1';
hidden_samlds.type = 'hidden';

var hidden_target = e('input');
hidden_target.name = 'target';
hidden_target.value = wayf_return_url;
hidden_target.type = 'hidden';

var idp_list = e('select', 'user_idp');
idp_list.name = 'entityID';
idp_list.style = 'margin-top: 15px; margin-bottom: 10px; width: 100%;';

var placeholder = e('option', null);
placeholder.value = '-';
placeholder.innerText = 'Select the organisation you are affiliated with ...';

var spacer = e('div', 'wayf_spacer');
spacer.style = 'clear: both; min-height: 1rem; margin-bottom: 0.5rem;';

var submit = e('input', 'wayf_submit_button');
submit.type = 'submit';
submit.value = 'Login';
submit.style = 'float: right;';

idp_list.appendChild(placeholder);

idp_entities.sort(function(a, b) { return a.name.localeCompare(b.name); });

for (var i = 0; i < idp_entities.length; ++i) {
  var idp = idp_entities[i];

  var option = e('option', null)
  option.innerText = idp.name;
  option.value = idp.entity_id;

  idp_list.appendChild(option);
}

spacer.appendChild(submit);

form.appendChild(hidden_samlds);
form.appendChild(hidden_target);
form.appendChild(idp_list);
form.appendChild(spacer);

logo_link.appendChild(logo);
logo_div.appendChild(logo_link);

wayf_div.appendChild(logo_div);
wayf_div.appendChild(label);
wayf_div.appendChild(form);

document.write(wayf_div.outerHTML);
