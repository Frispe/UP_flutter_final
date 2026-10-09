#!/usr/bin/env node

'use strict';

const http = require('node:http');
const crypto = require('node:crypto');

const args = process.argv.slice(2);
function arg(name, fallback) {
  const index = args.indexOf(`--${name}`);
  return index !== -1 && args[index + 1] ? args[index + 1] : fallback;
}

const PORT = Number(arg('port', 8080));
const ORIGIN = arg('origin', '*');
const SECRET = 'digital-shop-study-secret';
const ACCESS_TTL = Number(arg('ttl', 900));
const REFRESH_TTL = 60 * 60 * 24 * 7;

let db;

function hash(password) {
  return crypto.createHash('sha256').update(password + SECRET).digest('hex');
}

function sign(payload) {
  const body = Buffer.from(JSON.stringify({ ...payload, jti: crypto.randomUUID() })).toString('base64url');
  const signature = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  return `${body}.${signature}`;
}

function verify(token) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const [body, signature] = token.split('.');
  const expected = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  if (signature !== expected) return null;
  try {
    const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
    if (payload.exp && payload.exp * 1000 < Date.now()) return null;
    return payload;
  } catch {
    return null;
  }
}

function push(collection, value) {
  db.seq[collection] = (db.seq[collection] || 0) + 1;
  const id = db.seq[collection];
  db[collection].push({
    id,
    ...value,
    createdAt: new Date().toISOString(),
    deletedAt: null,
  });
  return id;
}

function seed() {
  db = {
    seq: {},
    brands: [],
    categories: [],
    platforms: [],
    products: [],
    customers: [],
    carts: [],
    cartItems: [],
    orders: [],
    orderItems: [],
    accounts: [],
    refreshTokens: new Set(),
  };

  const steam = push('platforms', { name: 'Steam' });
  const xbox = push('platforms', { name: 'Xbox' });
  const playstation = push('platforms', { name: 'PlayStation' });
  const web = push('platforms', { name: 'Web' });
  const windows = push('platforms', { name: 'Windows' });

  const games = push('categories', { name: 'Игры' });
  const subscriptions = push('categories', { name: 'Подписки' });
  const action = push('categories', { name: 'Экшен' });
  const strategy = push('categories', { name: 'Стратегии' });
  const ai = push('categories', { name: 'Нейросети' });
  const software = push('categories', { name: 'Программы' });

  const valve = push('brands', { name: 'Valve', platformIds: [steam] });
  const microsoft = push('brands', { name: 'Microsoft', platformIds: [xbox, windows] });
  const sony = push('brands', { name: 'Sony', platformIds: [playstation] });
  const rockstar = push('brands', { name: 'Rockstar Games', platformIds: [steam, xbox, playstation] });
  const openai = push('brands', { name: 'OpenAI', platformIds: [web] });
  const midjourney = push('brands', { name: 'Midjourney', platformIds: [web] });
  const anthropic = push('brands', { name: 'Anthropic', platformIds: [web] });
  const adobe = push('brands', { name: 'Adobe', platformIds: [web, windows] });

  const product = (name, sku, type, brandId, price, platformId, categoryIds, region, durationMonths = null) =>
    push('products', {
      name,
      sku,
      description: `Цифровой товар «${name}»`,
      type,
      brandId,
      price,
      platformId,
      categoryIds,
      region,
      durationMonths,
    });

  product('Counter-Strike 2 Prime', 'CS2-RU', 'gameKey', valve, 1490, steam, [games, action], 'Россия');
  product('Counter-Strike 2 Prime', 'CS2-KZ', 'gameKey', valve, 1390, steam, [games, action], 'Казахстан');
  product('Forza Horizon 5', 'FH5-RU', 'gameKey', microsoft, 3490, xbox, [games], 'Россия');
  product('Forza Horizon 5', 'FH5-KZ', 'gameKey', microsoft, 3290, xbox, [games], 'Казахстан');
  product('Minecraft Java & Bedrock', 'MC-PC', 'gameKey', microsoft, 2590, windows, [games], 'Весь мир');
  product('God of War', 'GOW-PS', 'gameKey', sony, 3990, playstation, [games, action], 'Россия');
  product('The Last of Us Part I', 'TLOU-PS', 'gameKey', sony, 4490, playstation, [games, action], 'Казахстан');
  product('Grand Theft Auto V', 'GTAV-RU', 'gameKey', rockstar, 1990, steam, [games, action], 'Россия');
  product('Red Dead Redemption 2', 'RDR2-KZ', 'gameKey', rockstar, 2990, steam, [games, action], 'Казахстан');
  product('Age of Empires IV', 'AOE4-PC', 'gameKey', microsoft, 2290, steam, [games, strategy], 'Весь мир');
  product('ChatGPT Plus 1 месяц', 'GPT-1M', 'aiSubscription', openai, 2490, web, [subscriptions, ai], 'Весь мир', 1);
  product('ChatGPT Plus 3 месяца', 'GPT-3M', 'aiSubscription', openai, 6990, web, [subscriptions, ai], 'Весь мир', 3);
  product('ChatGPT Plus 12 месяцев', 'GPT-12M', 'aiSubscription', openai, 24990, web, [subscriptions, ai], 'Весь мир', 12);
  product('Midjourney Basic 1 месяц', 'MJ-B1', 'aiSubscription', midjourney, 1290, web, [subscriptions, ai], 'Весь мир', 1);
  product('Midjourney Standard 1 месяц', 'MJ-S1', 'aiSubscription', midjourney, 2990, web, [subscriptions, ai], 'Весь мир', 1);
  product('Claude Pro 1 месяц', 'CL-P1', 'aiSubscription', anthropic, 2390, web, [subscriptions, ai], 'Весь мир', 1);
  product('Claude Pro 3 месяца', 'CL-P3', 'aiSubscription', anthropic, 6690, web, [subscriptions, ai], 'Весь мир', 3);
  product('Adobe Creative Cloud 1 месяц', 'ACC-1M', 'aiSubscription', adobe, 3990, web, [subscriptions, software], 'Весь мир', 1);
  product('Adobe Photoshop 12 месяцев', 'PS-12M', 'aiSubscription', adobe, 15990, windows, [subscriptions, software], 'Весь мир', 12);
  product('Xbox Game Pass Ultimate', 'GPU-3M', 'aiSubscription', microsoft, 3490, xbox, [subscriptions, games], 'Казахстан', 3);

  const customers = [
    ['Алексей Смирнов', 'alex@example.com', 'alex_play'],
    ['Мария Иванова', 'maria@example.com', 'maria_i'],
    ['Даниил Петров', 'danil@example.com', 'dan_petrov'],
    ['Анна Соколова', 'anna@example.com', 'anna_s'],
    ['Илья Орлов', 'ilya@example.com', 'orlov'],
  ];
  for (const [name, email, nickname] of customers) {
    const customerId = push('customers', { name, email, nickname });
    push('carts', { customerId });
  }
  push('cartItems', { cartId: 1, productId: 1, quantity: 1 });
  push('cartItems', { cartId: 1, productId: 11, quantity: 1 });

  push('accounts', {
    username: 'admin',
    passwordHash: hash('admin123'),
    name: 'Администратор',
    email: 'admin@digital-shop.local',
    role: 'admin',
    customerId: null,
  });
  push('accounts', {
    username: 'manager',
    passwordHash: hash('manager123'),
    name: 'Менеджер',
    email: 'manager@digital-shop.local',
    role: 'manager',
    customerId: null,
  });
  push('accounts', {
    username: 'customer',
    passwordHash: hash('customer123!'),
    name: 'Алексей Смирнов',
    email: 'alex@example.com',
    role: 'customer',
    customerId: 1,
  });
}

const RESOURCES = {
  products: 'products',
  brands: 'brands',
  categories: 'categories',
  platforms: 'platforms',
  customers: 'customers',
  carts: 'carts',
  'cart-items': 'cartItems',
  orders: 'orders',
  'order-items': 'orderItems',
};

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Vary', 'Origin');
}

function send(res, status, payload) {
  cors(res);
  if (payload === undefined || status === 204) {
    res.writeHead(204);
    res.end();
    return;
  }
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function fail(res, status, message) {
  send(res, status, { message });
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

function currentAccount(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return null;
  const payload = verify(header.slice(7));
  if (!payload || payload.type !== 'access') return null;
  return db.accounts.find((account) => account.id === payload.sub && !account.deletedAt) || null;
}

const ROLE_LEVEL = { customer: 1, manager: 2, admin: 3 };
function requireRole(res, account, role) {
  if (!account) {
    fail(res, 401, 'Требуется вход в систему');
    return false;
  }
  if ((ROLE_LEVEL[account.role] || 0) < ROLE_LEVEL[role]) {
    fail(res, 403, 'Недостаточно прав для этого действия');
    return false;
  }
  return true;
}

function publicAccount(account) {
  return {
    id: account.id,
    username: account.username,
    name: account.name,
    email: account.email,
    role: account.role,
    customerId: account.customerId,
    createdAt: account.createdAt,
    deletedAt: account.deletedAt,
  };
}

function issueSession(account) {
  const now = Math.floor(Date.now() / 1000);
  const accessToken = sign({ sub: account.id, role: account.role, type: 'access', exp: now + ACCESS_TTL });
  const refreshToken = sign({ sub: account.id, type: 'refresh', exp: now + REFRESH_TTL });
  db.refreshTokens.add(refreshToken);
  return { accessToken, refreshToken, expiresIn: ACCESS_TTL, user: publicAccount(account) };
}

function ownsCart(account, cartId) {
  const cart = db.carts.find((row) => row.id === Number(cartId) && !row.deletedAt);
  return Boolean(cart && account && cart.customerId === account.customerId);
}

function canReadRow(account, collection, row) {
  if (!['customers', 'carts', 'cartItems', 'orders', 'orderItems'].includes(collection)) return true;
  if (!account) return false;
  if (account.role !== 'customer') return true;
  if (collection === 'customers') return row.id === account.customerId;
  if (collection === 'carts') return row.customerId === account.customerId;
  if (collection === 'cartItems') return ownsCart(account, row.cartId);
  if (collection === 'orders') return row.customerId === account.customerId;
  const order = db.orders.find((item) => item.id === row.orderId && !item.deletedAt);
  return Boolean(order && order.customerId === account.customerId);
}

function searchableText(collection, row) {
  if (collection === 'products') return [row.name, row.sku, row.description, row.region].join(' ');
  if (collection === 'customers') return [row.name, row.email, row.nickname].join(' ');
  if (collection === 'orders') return [row.status, row.id, row.customerId].join(' ');
  return [row.name].join(' ');
}

function applyFilters(collection, rows, query) {
  let result = rows;
  if (query.search) {
    const value = String(query.search).trim().toLowerCase();
    result = result.filter((row) => searchableText(collection, row).toLowerCase().includes(value));
  }
  if (collection === 'products') {
    if (query.type) result = result.filter((row) => row.type === query.type);
    if (query.brandId) result = result.filter((row) => row.brandId === Number(query.brandId));
    if (query.platformId) result = result.filter((row) => row.platformId === Number(query.platformId));
    if (query.categoryId) result = result.filter((row) => row.categoryIds.includes(Number(query.categoryId)));
    if (query.priceFrom) result = result.filter((row) => row.price >= Number(query.priceFrom));
    if (query.priceTo) result = result.filter((row) => row.price <= Number(query.priceTo));
  }
  if (collection === 'brands' && query.platformId) {
    result = result.filter((row) => row.platformIds.includes(Number(query.platformId)));
  }
  if (['brands', 'categories', 'platforms'].includes(collection) && query.hasProducts) {
    const expected = query.hasProducts === 'true';
    result = result.filter((row) => (row.productCount > 0) === expected);
  }
  if (collection === 'customers' && query.hasCartItems) {
    const expected = query.hasCartItems === 'true';
    result = result.filter((row) => (row.cartItemCount > 0) === expected);
  }
  if (collection === 'orders') {
    if (query.customerId) result = result.filter((row) => row.customerId === Number(query.customerId));
    if (query.status) result = result.filter((row) => row.status === query.status);
  }
  if (collection === 'carts' && query.customerId) {
    result = result.filter((row) => row.customerId === Number(query.customerId));
  }
  if (collection === 'cartItems' && query.cartId) {
    result = result.filter((row) => row.cartId === Number(query.cartId));
  }
  if (collection === 'orderItems' && query.orderId) {
    result = result.filter((row) => row.orderId === Number(query.orderId));
  }
  return result;
}

function enrichRows(collection, rows) {
  if (collection === 'brands') {
    return rows.map((row) => ({
      ...row,
      productCount: db.products.filter((product) => !product.deletedAt && product.brandId === row.id).length,
    }));
  }
  if (collection === 'categories') {
    return rows.map((row) => ({
      ...row,
      productCount: db.products.filter((product) => !product.deletedAt && product.categoryIds.includes(row.id)).length,
    }));
  }
  if (collection === 'platforms') {
    return rows.map((row) => ({
      ...row,
      productCount: db.products.filter((product) => !product.deletedAt && product.platformId === row.id).length,
    }));
  }
  if (collection === 'customers') {
    return rows.map((row) => {
      const cartIds = db.carts.filter((cart) => !cart.deletedAt && cart.customerId === row.id).map((cart) => cart.id);
      return {
        ...row,
        cartItemCount: db.cartItems.filter((item) => !item.deletedAt && cartIds.includes(item.cartId)).length,
      };
    });
  }
  return rows;
}

function sortRows(rows, sort) {
  const [field, direction = 'asc'] = String(sort || 'id,asc').split(',');
  const multiplier = direction.toLowerCase() === 'desc' ? -1 : 1;
  return [...rows].sort((a, b) => {
    const left = a[field];
    const right = b[field];
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    if (typeof left === 'number' && typeof right === 'number') return (left - right) * multiplier;
    return String(left).localeCompare(String(right), 'ru') * multiplier;
  });
}

function paginate(rows, query) {
  const page = Math.max(1, Number(query.page) || 1);
  const size = Math.min(100, Math.max(1, Number(query.size) || 10));
  const total = rows.length;
  return {
    items: rows.slice((page - 1) * size, page * size),
    page,
    size,
    total,
    totalPages: Math.max(1, Math.ceil(total / size)),
  };
}

function exists(collection, id) {
  return db[collection].some((row) => row.id === Number(id) && !row.deletedAt);
}

function validate(collection, body, id = null) {
  const errors = {};
  const text = (value) => (typeof value === 'string' ? value.trim() : '');
  const unique = (field, value) =>
    !db[collection].some((row) => row.id !== id && !row.deletedAt && String(row[field]).toLowerCase() === value.toLowerCase());

  if (['brands', 'categories', 'platforms'].includes(collection)) {
    if (!text(body.name)) errors.name = 'Укажите название';
    else if (!unique('name', text(body.name))) errors.name = 'Запись с таким названием уже существует';
  }
  if (collection === 'products') {
    if (!text(body.name)) errors.name = 'Укажите название товара';
    if (!text(body.sku)) errors.sku = 'Укажите артикул';
    else if (!unique('sku', text(body.sku))) errors.sku = 'Товар с таким артикулом уже существует';
    if (!['gameKey', 'aiSubscription'].includes(body.type)) errors.type = 'Выберите тип товара';
    if (!exists('brands', body.brandId)) errors.brandId = 'Бренд не найден';
    if (!exists('platforms', body.platformId)) errors.platformId = 'Платформа не найдена';
    const price = Number(body.price);
    if (!Number.isInteger(price) || price <= 0) errors.price = 'Стоимость должна быть положительным целым числом';
    if (!text(body.region)) errors.region = 'Укажите регион активации';
    const categoryIds = Array.isArray(body.categoryIds) ? body.categoryIds.map(Number) : [];
    if (!categoryIds.length || categoryIds.some((categoryId) => !exists('categories', categoryId))) {
      errors.categoryIds = 'Выберите существующую категорию';
    }
    if (body.type === 'aiSubscription') {
      const duration = Number(body.durationMonths);
      if (!Number.isInteger(duration) || duration <= 0) errors.durationMonths = 'Укажите срок подписки';
    }
  }
  if (collection === 'customers') {
    if (!text(body.name)) errors.name = 'Укажите имя пользователя';
    if (!text(body.email)) errors.email = 'Укажите электронную почту';
    else if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(text(body.email))) errors.email = 'Некорректный адрес почты';
    else if (!unique('email', text(body.email))) errors.email = 'Пользователь с такой почтой уже существует';
    if (!text(body.nickname)) errors.nickname = 'Укажите никнейм';
    else if (!unique('nickname', text(body.nickname))) errors.nickname = 'Такой никнейм уже занят';
  }
  if (collection === 'carts') {
    if (!exists('customers', body.customerId)) errors.customerId = 'Пользователь не найден';
    else if (db.carts.some((row) => row.id !== id && !row.deletedAt && row.customerId === Number(body.customerId))) {
      errors.customerId = 'У пользователя уже есть корзина';
    }
  }
  if (collection === 'cartItems') {
    if (!exists('carts', body.cartId)) errors.cartId = 'Корзина не найдена';
    if (!exists('products', body.productId)) errors.productId = 'Товар не найден';
    const quantity = Number(body.quantity);
    if (!Number.isInteger(quantity) || quantity < 1) errors.quantity = 'Количество должно быть больше нуля';
  }
  if (collection === 'orders') {
    if (!exists('customers', body.customerId)) errors.customerId = 'Пользователь не найден';
    if (!['new', 'paid', 'completed', 'cancelled'].includes(body.status)) errors.status = 'Некорректный статус заказа';
  }
  if (collection === 'orderItems') {
    if (!exists('orders', body.orderId)) errors.orderId = 'Заказ не найден';
    if (!exists('products', body.productId)) errors.productId = 'Товар не найден';
    const quantity = Number(body.quantity);
    const price = Number(body.price);
    if (!Number.isInteger(quantity) || quantity < 1) errors.quantity = 'Количество должно быть больше нуля';
    if (!Number.isInteger(price) || price <= 0) errors.price = 'Стоимость должна быть больше нуля';
  }
  return errors;
}

function normalize(collection, body) {
  const text = (value) => (value == null ? '' : String(value).trim());
  const number = (value) => (value == null || value === '' ? null : Number(value));
  const ids = (value) => Array.isArray(value) ? [...new Set(value.map(Number).filter(Number.isInteger))] : [];
  if (collection === 'brands') return { name: text(body.name), platformIds: ids(body.platformIds) };
  if (['categories', 'platforms'].includes(collection)) return { name: text(body.name) };
  if (collection === 'products') return {
    name: text(body.name),
    sku: text(body.sku),
    description: text(body.description),
    type: text(body.type),
    brandId: number(body.brandId),
    price: number(body.price),
    platformId: number(body.platformId),
    categoryIds: ids(body.categoryIds),
    region: text(body.region),
    durationMonths: body.type === 'aiSubscription' ? number(body.durationMonths) : null,
  };
  if (collection === 'customers') return { name: text(body.name), email: text(body.email), nickname: text(body.nickname) };
  if (collection === 'carts') return { customerId: number(body.customerId) };
  if (collection === 'cartItems') return { cartId: number(body.cartId), productId: number(body.productId), quantity: number(body.quantity) };
  if (collection === 'orders') return {
    customerId: number(body.customerId),
    status: text(body.status),
    totalPrice: number(body.totalPrice) || 0,
    orderedAt: body.orderedAt || new Date().toISOString(),
  };
  if (collection === 'orderItems') return {
    orderId: number(body.orderId),
    productId: number(body.productId),
    quantity: number(body.quantity),
    price: number(body.price),
  };
  return { ...body };
}

function hasReferences(collection, id) {
  if (collection === 'brands') return db.products.some((row) => row.brandId === id);
  if (collection === 'categories') return db.products.some((row) => row.categoryIds.includes(id));
  if (collection === 'platforms') return db.products.some((row) => row.platformId === id) || db.brands.some((brand) => brand.platformIds.includes(id));
  if (collection === 'products') return db.cartItems.some((row) => row.productId === id) || db.orderItems.some((row) => row.productId === id);
  if (collection === 'customers') return db.carts.some((row) => row.customerId === id) || db.orders.some((row) => row.customerId === id);
  if (collection === 'carts') return db.cartItems.some((row) => row.cartId === id);
  if (collection === 'orders') return db.orderItems.some((row) => row.orderId === id);
  return false;
}

async function handleAuth(req, res, path, method) {
  if (path === '/api/auth/register' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const username = String(body.username || '').trim();
    const password = String(body.password || '');
    const name = String(body.name || '').trim();
    const email = String(body.email || '').trim();
    const nickname = String(body.nickname || '').trim();
    const errors = {};
    if (username.length < 3) errors.username = 'Логин должен содержать не меньше 3 символов';
    else if (db.accounts.some((row) => !row.deletedAt && row.username.toLowerCase() === username.toLowerCase())) errors.username = 'Такой логин уже занят';
    if (password.length < 8 || !/\d/.test(password) || !/[^A-Za-zА-Яа-яЁё0-9]/.test(password)) errors.password = 'Пароль должен содержать не меньше 8 символов, цифру и специальный знак';
    if (!name) errors.name = 'Укажите имя';
    if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(email)) errors.email = 'Некорректный адрес почты';
    else if (db.customers.some((row) => !row.deletedAt && row.email.toLowerCase() === email.toLowerCase())) errors.email = 'Пользователь с такой почтой уже существует';
    if (!nickname) errors.nickname = 'Укажите никнейм';
    else if (db.customers.some((row) => !row.deletedAt && row.nickname.toLowerCase() === nickname.toLowerCase())) errors.nickname = 'Такой никнейм уже занят';
    if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });
    const customerId = push('customers', { name, email, nickname });
    push('carts', { customerId });
    const accountId = push('accounts', { username, passwordHash: hash(password), name, email, role: 'customer', customerId });
    const account = db.accounts.find((row) => row.id === accountId);
    return send(res, 201, issueSession(account));
  }
  if (path === '/api/auth/login' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const account = db.accounts.find((row) => row.username === String(body.username || '').trim() && !row.deletedAt);
    if (!account || account.passwordHash !== hash(String(body.password || ''))) return fail(res, 401, 'Неверный логин или пароль');
    return send(res, 200, issueSession(account));
  }
  if (path === '/api/auth/refresh' && method === 'POST') {
    const body = await readBody(req);
    const token = body && body.refreshToken;
    const payload = verify(token);
    if (!payload || payload.type !== 'refresh' || !db.refreshTokens.has(token)) return fail(res, 401, 'Токен обновления недействителен');
    const account = db.accounts.find((row) => row.id === payload.sub && !row.deletedAt);
    if (!account) return fail(res, 401, 'Учётная запись не найдена');
    db.refreshTokens.delete(token);
    return send(res, 200, issueSession(account));
  }
  if (path === '/api/auth/me' && method === 'GET') {
    const account = currentAccount(req);
    if (!account) return fail(res, 401, 'Требуется вход в систему');
    return send(res, 200, publicAccount(account));
  }
  if (path === '/api/auth/logout' && method === 'POST') {
    const body = await readBody(req);
    if (body && body.refreshToken) db.refreshTokens.delete(body.refreshToken);
    return send(res, 204);
  }
  return false;
}

async function handle(req, res, url) {
  const method = req.method.toUpperCase();
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const query = Object.fromEntries(url.searchParams.entries());
  const account = currentAccount(req);

  if (query.__fail) return fail(res, Number(query.__fail), 'Ошибка вызвана намеренно параметром __fail');
  if (path === '/api/__health' && method === 'GET') return send(res, 200, { status: 'ok', time: new Date().toISOString() });
  if (path === '/api/__reset' && method === 'POST') {
    seed();
    return send(res, 200, { message: 'Данные восстановлены в исходное состояние' });
  }
  if (path.startsWith('/api/auth/')) {
    const handled = await handleAuth(req, res, path, method);
    if (handled !== false) return handled;
  }

  if (path === '/api/statistics' && method === 'GET') {
    if (!requireRole(res, account, 'admin')) return;
    const activeOrders = db.orders.filter((row) => !row.deletedAt);
    return send(res, 200, {
      products: db.products.filter((row) => !row.deletedAt).length,
      customers: db.customers.filter((row) => !row.deletedAt).length,
      orders: activeOrders.length,
      revenue: activeOrders.filter((row) => row.status !== 'cancelled').reduce((sum, row) => sum + row.totalPrice, 0),
      roles: {
        customer: db.accounts.filter((row) => !row.deletedAt && row.role === 'customer').length,
        manager: db.accounts.filter((row) => !row.deletedAt && row.role === 'manager').length,
        admin: db.accounts.filter((row) => !row.deletedAt && row.role === 'admin').length,
      },
    });
  }

  if (path === '/api/accounts' && method === 'GET') {
    if (!requireRole(res, account, 'admin')) return;
    let rows = db.accounts.filter((row) => query.includeDeleted === 'true' || !row.deletedAt).map(publicAccount);
    if (query.search) {
      const value = query.search.toLowerCase();
      rows = rows.filter((row) => [row.username, row.name, row.email, row.role].join(' ').toLowerCase().includes(value));
    }
    return send(res, 200, paginate(sortRows(rows, query.sort), query));
  }

  const accountRole = path.match(/^\/api\/accounts\/(\d+)\/role$/);
  if (accountRole && method === 'PATCH') {
    if (!requireRole(res, account, 'admin')) return;
    const target = db.accounts.find((row) => row.id === Number(accountRole[1]) && !row.deletedAt);
    if (!target) return fail(res, 404, 'Учётная запись не найдена');
    if (target.id === account.id) return fail(res, 409, 'Нельзя изменить роль текущей учётной записи');
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    if (!['customer', 'manager', 'admin'].includes(body.role)) return send(res, 422, { message: 'Ошибка валидации', errors: { role: 'Выберите существующую роль' } });
    target.role = body.role;
    return send(res, 200, publicAccount(target));
  }

  const checkout = path.match(/^\/api\/carts\/(\d+)\/checkout$/);
  if (checkout && method === 'POST') {
    if (!requireRole(res, account, 'customer')) return;
    const cart = db.carts.find((row) => row.id === Number(checkout[1]) && !row.deletedAt);
    if (!cart) return fail(res, 404, 'Корзина не найдена');
    if (account.role === 'customer' && cart.customerId !== account.customerId) return fail(res, 403, 'Можно оформить только собственную корзину');
    const items = db.cartItems.filter((row) => row.cartId === cart.id && !row.deletedAt);
    if (!items.length) return fail(res, 409, 'Нельзя оформить пустую корзину');
    let totalPrice = 0;
    const prepared = [];
    for (const item of items) {
      const product = db.products.find((row) => row.id === item.productId && !row.deletedAt);
      if (!product) return fail(res, 409, `Товар с кодом ${item.productId} больше недоступен`);
      totalPrice += product.price * item.quantity;
      prepared.push({ productId: product.id, quantity: item.quantity, price: product.price });
    }
    const orderId = push('orders', {
      customerId: cart.customerId,
      status: 'new',
      totalPrice,
      orderedAt: new Date().toISOString(),
    });
    for (const item of prepared) push('orderItems', { orderId, ...item });
    db.cartItems = db.cartItems.filter((row) => row.cartId !== cart.id);
    const order = db.orders.find((row) => row.id === orderId);
    return send(res, 201, { ...order, items: db.orderItems.filter((row) => row.orderId === orderId) });
  }

  const bulkMatch = path.match(/^\/api\/([a-z-]+)\/bulk-delete$/);
  if (bulkMatch && method === 'POST') {
    const collection = RESOURCES[bulkMatch[1]];
    if (!collection) return fail(res, 404, 'Ресурс не найден');
    if (!requireRole(res, account, 'manager')) return;
    const body = await readBody(req);
    const ids = Array.isArray(body && body.ids) ? body.ids.map(Number) : [];
    if (!ids.length) return send(res, 422, { message: 'Ошибка валидации', errors: { ids: 'Передайте идентификаторы записей' } });
    let deleted = 0;
    for (const row of db[collection]) {
      if (ids.includes(row.id) && !row.deletedAt) {
        row.deletedAt = new Date().toISOString();
        deleted += 1;
      }
    }
    return send(res, 200, { deleted });
  }

  const match = path.match(/^\/api\/([a-z-]+)(?:\/(\d+))?(?:\/(restore))?$/);
  if (!match) return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);
  const collection = RESOURCES[match[1]];
  const id = match[2] ? Number(match[2]) : null;
  const action = match[3] || null;
  if (!collection) return fail(res, 404, 'Ресурс не найден');

  if (action === 'restore' && method === 'POST') {
    if (!requireRole(res, account, 'admin')) return;
    const row = db[collection].find((item) => item.id === id);
    if (!row) return fail(res, 404, 'Запись не найдена');
    row.deletedAt = null;
    return send(res, 200, row);
  }
  if (id === null && method === 'GET') {
    let rows = query.includeDeleted === 'true' ? db[collection] : db[collection].filter((row) => !row.deletedAt);
    if (['customers', 'carts', 'cartItems', 'orders', 'orderItems'].includes(collection)) {
      if (!account) return fail(res, 401, 'Требуется вход в систему');
      rows = rows.filter((row) => canReadRow(account, collection, row));
    }
    rows = enrichRows(collection, rows);
    rows = applyFilters(collection, rows, query);
    rows = sortRows(rows, query.sort);
    return send(res, 200, paginate(rows, query));
  }
  if (id !== null && method === 'GET') {
    const row = db[collection].find((item) => item.id === id && (query.includeDeleted === 'true' || !item.deletedAt));
    if (!row) return fail(res, 404, 'Запись не найдена');
    if (!canReadRow(account, collection, row)) return fail(res, account ? 403 : 401, account ? 'Недостаточно прав для просмотра записи' : 'Требуется вход в систему');
    return send(res, 200, row);
  }
  if (id === null && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    if (collection === 'cartItems' && account && account.role === 'customer') {
      if (!ownsCart(account, body.cartId)) return fail(res, 403, 'Можно изменять только собственную корзину');
    } else if (!requireRole(res, account, 'manager')) return;
    const errors = validate(collection, body);
    if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });
    const newId = push(collection, normalize(collection, body));
    return send(res, 201, db[collection].find((row) => row.id === newId));
  }
  if (id !== null && (method === 'PUT' || method === 'PATCH')) {
    const row = db[collection].find((item) => item.id === id && !item.deletedAt);
    if (!row) return fail(res, 404, 'Запись не найдена');
    if (collection === 'cartItems' && account && account.role === 'customer') {
      if (!ownsCart(account, row.cartId)) return fail(res, 403, 'Можно изменять только собственную корзину');
    } else if (!requireRole(res, account, 'manager')) return;
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const merged = method === 'PATCH' ? { ...row, ...body } : body;
    const errors = validate(collection, merged, id);
    if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });
    Object.assign(row, normalize(collection, merged));
    return send(res, 200, row);
  }
  if (id !== null && method === 'DELETE') {
    const hard = query.hard === 'true';
    const index = db[collection].findIndex((row) => row.id === id);
    if (index === -1) return fail(res, 404, 'Запись не найдена');
    if (!hard && collection === 'cartItems' && account && account.role === 'customer') {
      if (!ownsCart(account, db[collection][index].cartId)) return fail(res, 403, 'Можно изменять только собственную корзину');
    } else if (!requireRole(res, account, hard ? 'admin' : 'manager')) return;
    if (hard) {
      if (hasReferences(collection, id)) return fail(res, 409, 'Запись используется в связанных данных и не может быть удалена окончательно');
      db[collection].splice(index, 1);
    } else {
      db[collection][index].deletedAt = new Date().toISOString();
    }
    return send(res, 204);
  }
  return fail(res, 405, 'Метод не поддерживается');
}

seed();

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    res.end();
    return;
  }
  const delay = Number(url.searchParams.get('__delay') || 0);
  if (delay > 0) await new Promise((resolve) => setTimeout(resolve, Math.min(delay, 10000)));
  const startedAt = Date.now();
  try {
    await handle(req, res, url);
  } catch (error) {
    console.error(error);
    if (!res.headersSent) fail(res, 500, `Внутренняя ошибка сервера: ${error.message}`);
  }
  console.log(`${req.method.padEnd(6)} ${url.pathname}${url.search} -> ${res.statusCode} ${Date.now() - startedAt} ms`);
});

server.listen(PORT, () => {
  console.log('');
  console.log('Учебное API «Магазин цифровых товаров»');
  console.log(`Адрес: http://localhost:${PORT}/api`);
  console.log(`Разрешённый источник: ${ORIGIN}`);
  console.log('Учётные записи: admin/admin123, manager/manager123, customer/customer123!');
  console.log('');
});
