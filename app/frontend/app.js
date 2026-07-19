const CONFIG = window.SPECY_DOCS_CONFIG || {};
const REPORT_PATH = CONFIG.reportPath || './report.json';
const MASKED_HEADER_KEYS = CONFIG.maskedHeaderKeys || [
  'Authorization'
];
const RAKE_TASK_HINT = CONFIG.rakeTaskHint || 'bin/rails specy_docs:report';

const MASKED_VALUE = '*****';
const HTTP_METHODS = ['get', 'put', 'post', 'delete'];

const endpointList = document.getElementById('endpoint-list');
const detail = document.getElementById('detail');
const status = document.getElementById('status');

let report = {};

async function loadReport() {
  const response = await fetch(REPORT_PATH);
  if (!response.ok) {
    throw new Error(`Failed to load ${REPORT_PATH} (${response.status})`);
  }

  report = await response.json();
  const paths = Object.keys(report);

  if (paths.length === 0) {
    status.textContent = `No captures in report.json. Run: ${RAKE_TASK_HINT}`;
    return;
  }

  status.hidden = true;
  renderEndpointList(paths);
  selectPath(paths[0]);
}

function renderEndpointList(paths) {
  endpointList.innerHTML = '';

  const groups = groupPathsByTopLevel(paths);

  Object.entries(groups).forEach(([group, groupPaths]) => {
    const section = document.createElement('section');
    section.className = 'endpoint-group';

    const heading = document.createElement('h2');
    heading.className = 'endpoint-group__title';
    heading.textContent = group;
    section.appendChild(heading);

    const list = document.createElement('div');
    list.className = 'endpoint-group__list';

    groupPaths.forEach((path) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'endpoint-button';
      button.dataset.path = path;

      const pathEl = document.createElement('span');
      pathEl.className = 'endpoint-button__path';
      pathEl.textContent = pathWithinGroup(path, group);

      const methodsEl = document.createElement('span');
      methodsEl.className = 'endpoint-button__methods';
      availableMethods(path).forEach((method) => {
        methodsEl.appendChild(methodBadge(method));
      });

      button.append(pathEl, methodsEl);
      button.addEventListener('click', () => selectPath(path));
      list.appendChild(button);
    });

    section.appendChild(list);
    endpointList.appendChild(section);
  });
}

function groupPathsByTopLevel(paths) {
  return paths.reduce((groups, path) => {
    const group = topLevelGroup(path);
    groups[group] ||= [];
    groups[group].push(path);
    return groups;
  }, {});
}

function topLevelGroup(path) {
  return path.split('/').filter(Boolean)[0] || '/';
}

function pathWithinGroup(path, group) {
  const prefix = `/${group}`;
  if (path === prefix) return '/';
  return path.startsWith(`${prefix}/`) ? path.slice(prefix.length) : path;
}

function availableMethods(path) {
  return HTTP_METHODS.filter((method) => (report[path]?.[method] || []).length > 0);
}

function selectPath(path) {
  endpointList.querySelectorAll('.endpoint-button').forEach((button) => {
    button.setAttribute('aria-current', button.dataset.path === path ? 'true' : 'false');
  });

  detail.hidden = false;
  detail.innerHTML = '';

  const heading = document.createElement('h2');
  heading.className = 'detail__path';
  heading.textContent = path;
  detail.appendChild(heading);

  const methods = availableMethods(path);
  if (methods.length === 0) {
    const empty = document.createElement('p');
    empty.className = 'status';
    empty.textContent = 'No examples for this path.';
    detail.appendChild(empty);
    return;
  }

  detail.appendChild(renderMethodTabs(path, methods));
}

function renderMethodTabs(path, methods) {
  const root = document.createElement('div');
  root.className = 'method-tabs';

  const tabList = document.createElement('div');
  tabList.className = 'method-tabs__list';
  tabList.setAttribute('role', 'tablist');
  tabList.setAttribute('aria-label', 'HTTP methods');

  const panels = document.createElement('div');
  panels.className = 'method-tabs__panels';

  methods.forEach((method, index) => {
    const captures = report[path][method];
    const selected = index === 0;
    const tabId = `method-tab-${method}`;
    const panelId = `method-panel-${method}`;

    const tab = document.createElement('button');
    tab.type = 'button';
    tab.className = `method-tabs__tab method-tabs__tab--${method}`;
    tab.id = tabId;
    tab.setAttribute('role', 'tab');
    tab.setAttribute('aria-selected', selected ? 'true' : 'false');
    tab.setAttribute('aria-controls', panelId);
    tab.tabIndex = selected ? 0 : -1;

    const label = document.createElement('span');
    label.className = 'method-tabs__label';
    label.textContent = method.toUpperCase();

    const count = document.createElement('span');
    count.className = 'method-tabs__count';
    count.textContent = String(captures.length);

    tab.append(label, count);
    tab.addEventListener('click', () => activateMethodTab(root, method));
    tabList.appendChild(tab);

    const panel = document.createElement('div');
    panel.className = 'method-tabs__panel';
    panel.id = panelId;
    panel.setAttribute('role', 'tabpanel');
    panel.setAttribute('aria-labelledby', tabId);
    panel.hidden = !selected;

    const accordions = document.createElement('div');
    accordions.className = 'capture-list';
    const accordionGroup = `${path}::${method}`;
    captures.forEach((capture, captureIndex) => {
      accordions.appendChild(renderCaptureAccordion(capture, captureIndex, accordionGroup));
    });
    panel.appendChild(accordions);
    panels.appendChild(panel);
  });

  root.append(tabList, panels);
  return root;
}

function activateMethodTab(root, method) {
  root.querySelectorAll('[role="tab"]').forEach((tab) => {
    const selected = tab.id === `method-tab-${method}`;
    tab.setAttribute('aria-selected', selected ? 'true' : 'false');
    tab.tabIndex = selected ? 0 : -1;
  });

  root.querySelectorAll('[role="tabpanel"]').forEach((panel) => {
    panel.hidden = panel.id !== `method-panel-${method}`;
  });
}

function renderCaptureAccordion(capture, index, accordionGroup) {
  const details = document.createElement('details');
  details.className = 'capture-accordion';
  details.name = accordionGroup;
  if (index === 0) {
    details.open = true;
  }

  const summary = document.createElement('summary');
  summary.className = 'capture-accordion__summary';

  const description = document.createElement('span');
  description.className = 'capture-accordion__description';
  description.textContent = shortenDescription(capture.description) || `Example ${index + 1}`;

  const meta = document.createElement('span');
  meta.className = 'capture-accordion__meta';

  const pathEl = document.createElement('span');
  pathEl.className = 'capture-accordion__path';
  pathEl.textContent = capture.request?.path || 'unknown path';

  meta.append(pathEl, statusPill(capture.response?.status));

  summary.append(description, meta);
  details.appendChild(summary);

  const body = document.createElement('div');
  body.className = 'capture-accordion__body';

  const grid = document.createElement('div');
  grid.className = 'capture__grid';
  grid.appendChild(
    renderPanel('Request', {
      method: capture.request?.method,
      path: capture.request?.path,
      query_string: capture.request?.query_string,
      headers: maskHeaders(capture.request?.headers),
      body: capture.request?.body
    })
  );

  const queryParams = parseQueryString(capture.request?.query_string);
  if (queryParams) {
    grid.appendChild(renderPanel('Query', queryParams));
  }

  const requestBody = parseJsonLike(capture.request?.body);
  if (requestBody !== null && requestBody !== undefined && requestBody !== '') {
    grid.appendChild(renderPanel('Body', requestBody));
  }

  grid.appendChild(
    renderPanel('Response', {
      status: capture.response?.status,
      headers: maskHeaders(capture.response?.headers),
      body: capture.response?.body
    })
  );
  body.appendChild(grid);
  details.appendChild(body);

  return details;
}

function parseQueryString(queryString) {
  if (!queryString || typeof queryString !== 'string') {
    return null;
  }

  const params = {};
  new URLSearchParams(queryString).forEach((value, key) => {
    if (Object.prototype.hasOwnProperty.call(params, key)) {
      params[key] = Array.isArray(params[key]) ? [...params[key], value] : [params[key], value];
    } else {
      params[key] = value;
    }
  });

  return Object.keys(params).length > 0 ? params : null;
}

function parseJsonLike(value) {
  if (value === null || value === undefined || value === '') {
    return null;
  }

  if (typeof value !== 'string') {
    return value;
  }

  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
}

function maskHeaders(headers) {
  if (!headers || typeof headers !== 'object') {
    return headers;
  }

  const maskedKeys = new Set(MASKED_HEADER_KEYS.map((key) => key.toLowerCase()));

  return Object.fromEntries(
    Object.entries(headers).map(([key, value]) => [
      key,
      maskedKeys.has(key.toLowerCase()) ? MASKED_VALUE : value
    ])
  );
}

function renderPanel(title, data) {
  const panel = document.createElement('div');
  panel.className = 'panel';

  const heading = document.createElement('h3');
  heading.textContent = title;

  const pre = document.createElement('pre');
  pre.className = 'code-block';
  pre.innerHTML = highlightJson(JSON.stringify(data, null, 2));

  panel.append(heading, pre);
  return panel;
}

function highlightJson(json) {
  const escaped = escapeHtml(json);

  return escaped.replace(
    /("(?:\\.|[^"\\])*")\s*:|\b(true|false|null)\b|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)|("(?:\\.|[^"\\])*")/g,
    (match, key, literal, number, string) => {
      if (key) {
        return `<span class="token token-key">${key}</span>:`;
      }
      if (literal) {
        return `<span class="token token-literal">${literal}</span>`;
      }
      if (number) {
        return `<span class="token token-number">${number}</span>`;
      }
      return `<span class="token token-string">${string}</span>`;
    }
  );
}

function escapeHtml(value) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}

function methodBadge(method) {
  const badge = document.createElement('span');
  badge.className = `method-badge method-badge--${method}`;
  badge.textContent = method;
  return badge;
}

// Prefer starting at the HTTP verb in RSpec descriptions, e.g.
// "behaves like … ReportBaseController GET /show with valid params …"
// → "GET /show with valid params …"
function shortenDescription(description) {
  if (!description) return '';

  const methodMatch = description.match(/\b(GET|PUT|POST|DELETE)\b/);
  if (methodMatch) {
    return description.slice(methodMatch.index).trim();
  }

  return description
    .replace(/^(?:[A-Z][\w]*)(?:::[A-Z][\w]*)*Controller\s+/, '')
    .trim();
}

function statusPill(statusCode) {
  const pill = document.createElement('span');
  const tone = statusTone(statusCode);
  pill.className = `status-pill status-pill--${tone}`;
  pill.textContent = statusCode ?? '—';
  return pill;
}

function statusTone(statusCode) {
  const code = Number(statusCode);
  if (!Number.isFinite(code)) return 'unknown';
  if (code >= 200 && code <= 299) return 'success';
  if (code >= 300 && code <= 399) return 'redirect';
  if (code >= 400 && code <= 499) return 'client-error';
  if (code >= 500 && code <= 599) return 'server-error';
  return 'unknown';
}

loadReport().catch((error) => {
  status.hidden = false;
  status.textContent = `${error.message}. Generate with ${RAKE_TASK_HINT}.`;
});
