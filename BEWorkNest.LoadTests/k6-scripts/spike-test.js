import { check, sleep } from 'k6';
import http from 'k6/http';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:5006';

export const options = {
    stages: [
        { duration: '2m', target: 10 },    // Normal load
        { duration: '10s', target: 200 },  // SPIKE! Sudden traffic burst
        { duration: '3m', target: 10 },    // Back to normal
        { duration: '10s', target: 200 },  // Another SPIKE!
        { duration: '3m', target: 10 },    // Back to normal
        { duration: '30s', target: 0 },    // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<1000'], // 95th percentile < 1s
        http_req_failed: ['rate<0.05'],    // Error rate < 5%
    },
};

export default function () {
    const res = http.get(`${BASE_URL}/health`);
    
    check(res, {
        'status is 200': (r) => r.status === 200,
        'response time < 2s': (r) => r.timings.duration < 2000,
    });

    sleep(1);
}
