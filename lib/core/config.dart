const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

const apiDelay = int.fromEnvironment('API_DELAY', defaultValue: 0);
const apiFail = int.fromEnvironment('API_FAIL', defaultValue: 0);
