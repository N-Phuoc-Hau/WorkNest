import { check, group, sleep } from 'k6';
import http from 'k6/http';
import { Counter, Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const apiLatency = new Trend('api_latency');
const requestCount = new Counter('request_count');

// Configuration
const BASE_URL = __ENV.BASE_URL || 'http://localhost:5006';
const TEST_DURATION = __ENV.TEST_DURATION || '1m';

export const options = {
    stages: [
        { duration: '30s', target: 10 },   // Ramp up to 10 users
        { duration: '1m', target: 50 },    // Stay at 50 users
        { duration: '30s', target: 100 },  // Spike to 100 users
        { duration: '1m', target: 50 },    // Scale down to 50
        { duration: '30s', target: 0 },    // Ramp down to 0
    ],
    thresholds: {
        http_req_duration: ['p(95)<500', 'p(99)<1000'], // 95% < 500ms, 99% < 1s
        http_req_failed: ['rate<0.05'],                 // Error rate < 5%
        errors: ['rate<0.05'],
    },
};

export default function () {
    group('Health Check', () => {
        const res = http.get(`${BASE_URL}/health`);
        
        const success = check(res, {
            'health check status is 200': (r) => r.status === 200,
            'health check has status field': (r) => JSON.parse(r.body).status === 'healthy',
        });

        errorRate.add(!success);
        apiLatency.add(res.timings.duration);
        requestCount.add(1);

        sleep(1);
    });

    group('Job Posts List', () => {
        const params = {
            headers: {
                'Accept': 'application/json',
            },
        };

        const res = http.get(`${BASE_URL}/api/jobpost?page=1&pageSize=20`, params);
        
        const success = check(res, {
            'job posts status is 200': (r) => r.status === 200,
            'response is JSON': (r) => r.headers['Content-Type']?.includes('application/json'),
            'response time < 500ms': (r) => r.timings.duration < 500,
        });

        errorRate.add(!success);
        apiLatency.add(res.timings.duration);
        requestCount.add(1);

        sleep(1);
    });

    group('Search Functionality', () => {
        const keywords = ['developer', 'designer', 'manager', 'engineer', 'analyst'];
        const keyword = keywords[Math.floor(Math.random() * keywords.length)];

        const res = http.get(`${BASE_URL}/api/search?keyword=${keyword}`);
        
        const success = check(res, {
            'search status is 200': (r) => r.status === 200,
            'search response time < 800ms': (r) => r.timings.duration < 800,
        });

        errorRate.add(!success);
        apiLatency.add(res.timings.duration);
        requestCount.add(1);

        sleep(2);
    });
}

// Scenario: Stress Test
export function stressTest() {
    const res = http.get(`${BASE_URL}/api/jobpost?page=1&pageSize=50`);
    
    check(res, {
        'stress test status is 200': (r) => r.status === 200,
    });

    sleep(0.5);
}

// Scenario: Spike Test
export function spikeTest() {
    const res = http.get(`${BASE_URL}/health`);
    
    check(res, {
        'spike test status is 200': (r) => r.status === 200,
    });
}

export function handleSummary(data) {
    return {
        'reports/k6-summary.html': htmlReport(data),
        'reports/k6-summary.json': JSON.stringify(data),
        stdout: textSummary(data, { indent: ' ', enableColors: true }),
    };
}

function htmlReport(data) {
    const html = `
<!DOCTYPE html>
<html>
<head>
    <title>K6 Load Test Report - WorkNest API</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        .metric { background: #f9f9f9; padding: 15px; margin: 10px 0; border-left: 4px solid #4CAF50; }
        .metric-name { font-weight: bold; color: #555; }
        .metric-value { font-size: 24px; color: #4CAF50; }
        .failed { border-left-color: #f44336; }
        .failed .metric-value { color: #f44336; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; }
        tr:hover { background-color: #f5f5f5; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 WorkNest API - Load Test Results</h1>
        <p><strong>Test Date:</strong> ${new Date().toISOString()}</p>
        
        <h2>📊 Key Metrics</h2>
        <div class="metric">
            <div class="metric-name">Total Requests</div>
            <div class="metric-value">${data.metrics.http_reqs?.values.count || 0}</div>
        </div>
        
        <div class="metric ${data.metrics.http_req_failed?.values.rate > 0.05 ? 'failed' : ''}">
            <div class="metric-name">Error Rate</div>
            <div class="metric-value">${((data.metrics.http_req_failed?.values.rate || 0) * 100).toFixed(2)}%</div>
        </div>
        
        <div class="metric">
            <div class="metric-name">Average Response Time</div>
            <div class="metric-value">${(data.metrics.http_req_duration?.values.avg || 0).toFixed(2)} ms</div>
        </div>
        
        <div class="metric">
            <div class="metric-name">P95 Response Time</div>
            <div class="metric-value">${(data.metrics.http_req_duration?.values['p(95)'] || 0).toFixed(2)} ms</div>
        </div>
        
        <h2>📈 Detailed Metrics</h2>
        <table>
            <thead>
                <tr>
                    <th>Metric</th>
                    <th>Average</th>
                    <th>Min</th>
                    <th>Max</th>
                    <th>P90</th>
                    <th>P95</th>
                </tr>
            </thead>
            <tbody>
                ${Object.keys(data.metrics).map(key => {
                    const metric = data.metrics[key];
                    if (metric.type === 'trend') {
                        return `
                            <tr>
                                <td>${key}</td>
                                <td>${metric.values.avg?.toFixed(2) || 'N/A'}</td>
                                <td>${metric.values.min?.toFixed(2) || 'N/A'}</td>
                                <td>${metric.values.max?.toFixed(2) || 'N/A'}</td>
                                <td>${metric.values['p(90)']?.toFixed(2) || 'N/A'}</td>
                                <td>${metric.values['p(95)']?.toFixed(2) || 'N/A'}</td>
                            </tr>
                        `;
                    }
                    return '';
                }).join('')}
            </tbody>
        </table>
    </div>
</body>
</html>
    `;
    return html;
}

function textSummary(data, options) {
    return `
╔═══════════════════════════════════════════════════════════════╗
║              K6 Load Test Summary - WorkNest API              ║
╚═══════════════════════════════════════════════════════════════╝

Total Requests: ${data.metrics.http_reqs?.values.count || 0}
Error Rate: ${((data.metrics.http_req_failed?.values.rate || 0) * 100).toFixed(2)}%
Avg Response Time: ${(data.metrics.http_req_duration?.values.avg || 0).toFixed(2)} ms
P95 Response Time: ${(data.metrics.http_req_duration?.values['p(95)'] || 0).toFixed(2)} ms
P99 Response Time: ${(data.metrics.http_req_duration?.values['p(99)'] || 0).toFixed(2)} ms

Test Duration: ${data.state.testRunDurationMs}ms
VUs: ${data.metrics.vus?.values.value || 0}
    `;
}
