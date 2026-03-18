import { check, sleep } from 'k6';
import http from 'k6/http';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:5006';

export const options = {
    stages: [
        { duration: '1m', target: 10 },    // Normal load
        { duration: '2m', target: 50 },    // Increased load
        { duration: '2m', target: 100 },   // High load
        { duration: '2m', target: 200 },   // Very high load
        { duration: '2m', target: 300 },   // Extreme load - finding breaking point
        { duration: '1m', target: 0 },     // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(99)<2000'], // 99% of requests should be below 2s
        http_req_failed: ['rate<0.10'],    // Error rate should be below 10%
    },
};

export default function () {
    // Random endpoint selection
    const endpoints = [
        '/health',
        '/api/jobpost?page=1&pageSize=10',
        '/api/search?keyword=developer',
        '/api/jobpost?page=2&pageSize=20',
    ];

    const endpoint = endpoints[Math.floor(Math.random() * endpoints.length)];
    const res = http.get(`${BASE_URL}${endpoint}`);

    check(res, {
        'status is 200 or 500': (r) => r.status === 200 || r.status === 500,
        'response received': (r) => r.body.length > 0,
    });

    sleep(0.5);
}
