# 🚀 WorkNest API - Load Testing Project

## 📋 Overview

Comprehensive load testing suite cho WorkNest API sử dụng **NBomber** framework.

## ✨ Features

- ✅ **7 test scenarios** - Health, Auth, Jobs, Search, Stress, Spike, Endurance
- ✅ **Automated reporting** - HTML & Markdown reports
- ✅ **Real-time metrics** - Performance tracking during tests
- ✅ **Configurable** - Easily adjust load parameters
- ✅ **Multi-tool support** - NBomber, k6, Artillery

## 🏗️ Project Structure

```
BEWorkNest.LoadTests/
├── Program.cs                    # Main NBomber test runner
├── appsettings.json             # Test configuration
├── k6-scripts/                  # k6 JavaScript tests
│   ├── basic-load-test.js
│   ├── stress-test.js
│   └── spike-test.js
├── artillery-config.yml         # Artillery YAML config
├── artillery-processor.js       # Artillery helper functions
├── reports/                     # Generated test reports
└── LOAD_TESTING_GUIDE.md       # Complete documentation
```

## 🚀 Quick Start

### 1. Prerequisites

```bash
# .NET 8.0 SDK
dotnet --version

# (Optional) k6 for JavaScript tests
# https://k6.io/docs/getting-started/installation/

# (Optional) Artillery for YAML tests
npm install -g artillery
```

### 2. Build

```bash
dotnet build
```

### 3. Run Tests

**Option A: Interactive Menu (Recommended)**
```bash
# From workspace root
./run-load-tests.sh    # Linux/Mac
run-load-tests.bat     # Windows
```

**Option B: Direct Command**
```bash
# From BEWorkNest.LoadTests folder
dotnet run --configuration Release -- [test-type]
```

**Test types:**
- `health` - Quick health check (30s)
- `auth` - Authentication load (1 min)
- `jobs` - Job posts load (1 min)
- `search` - Search load (1 min)
- `stress` - Find breaking point (3 min)
- `spike` - Traffic bursts (2 min)
- `endurance` - Sustained load (10 min)
- `all` - All tests combined (2 min)

### 4. View Results

Reports are generated in `reports/` folder:
- `report_[timestamp].html` - Visual report
- `report_[timestamp].md` - Markdown report

## 📊 Test Scenarios

### 1. Health Check Test
**Duration:** 30 seconds  
**Load:** 10 RPS  
**Purpose:** Verify basic API availability

```bash
dotnet run -- health
```

### 2. Authentication Test
**Duration:** 1 minute  
**Load:** 5-20 RPS (ramping)  
**Purpose:** Test login endpoint under load

```bash
dotnet run -- auth
```

### 3. Job Posts Test
**Duration:** 1 minute  
**Load:** Ramp 10→20 RPS, sustain 20 RPS, ramp down  
**Purpose:** Test job listing endpoint

```bash
dotnet run -- jobs
```

### 4. Search Test
**Duration:** 1 minute  
**Load:** 15 RPS constant  
**Purpose:** Test search functionality with random keywords

```bash
dotnet run -- search
```

### 5. Stress Test
**Duration:** 3 minutes  
**Load:** Ramp 10→50→100 RPS, sustain, ramp down  
**Purpose:** Find system breaking point

```bash
dotnet run -- stress
```

### 6. Spike Test
**Duration:** 2 minutes  
**Load:** 5 RPS → SPIKE to 100 RPS → back to 5 RPS  
**Purpose:** Test sudden traffic bursts

```bash
dotnet run -- spike
```

### 7. Endurance Test
**Duration:** 10 minutes  
**Load:** 30 RPS constant  
**Purpose:** Check for memory leaks, degradation over time

```bash
dotnet run -- endurance
```

### 8. All Tests
**Duration:** 2 minutes  
**Load:** Multiple concurrent scenarios  
**Purpose:** Comprehensive performance overview

```bash
dotnet run -- all
```

## ⚙️ Configuration

### appsettings.json

```json
{
  "LoadTest": {
    "BaseUrl": "http://localhost:5000",
    "TestDuration": "00:01:00",
    "Scenarios": {
      "JobPosts": {
        "Enabled": true,
        "CopiesCount": 20,
        "Duration": "00:01:00"
      }
    },
    "Thresholds": {
      "TargetRPS": 100,
      "MaxLatencyMs": 500,
      "MinSuccessRate": 95.0
    }
  }
}
```

**Key settings:**
- `BaseUrl` - Target API URL
- `CopiesCount` - Number of concurrent virtual users
- `Duration` - Test duration
- `TargetRPS` - Target requests per second
- `MaxLatencyMs` - Maximum acceptable latency
- `MinSuccessRate` - Minimum success rate (%)

## 📈 Understanding Results

### Key Metrics

**1. RPS (Requests Per Second)**
- Measures throughput
- Target: > 100 RPS
- Good: 200+ RPS

**2. Latency Percentiles**
- P50 (Median): Typical response time
- P95: 95% of requests faster than this
- P99: 99% of requests faster than this

**Targets:**
- P50: < 100ms
- P95: < 500ms
- P99: < 1000ms

**3. Success Rate**
- Percentage of successful requests
- Target: > 95%
- Production: > 99%

**4. Error Rate**
- Percentage of failed requests
- Target: < 5%
- Production: < 1%

### Sample Output

```
┌──────────────────────────────────────────┐
│ Scenario: job_posts_load                 │
├──────────────────────────────────────────┤
│ Total Requests:    3,250                 │
│ Success:          99.2%                  │
│ RPS:              245.3                  │
│ Latency:                                 │
│   P50:            78ms                   │
│   P95:            423ms                  │
│   P99:            856ms                  │
└──────────────────────────────────────────┘

✅ Test PASSED - All thresholds met
```

## 🔧 Advanced Usage

### Custom Base URL

```bash
# Test against production API
dotnet run -- all --base-url https://api.worknest.com
```

### Modify Load Parameters

Edit `Program.cs` to customize load simulations:

```csharp
.WithLoadSimulations(
    Simulation.Inject(
        rate: 50,                    // 50 requests
        interval: TimeSpan.FromSeconds(1), // per second
        during: TimeSpan.FromMinutes(2)    // for 2 minutes
    )
)
```

### Add Custom Scenario

```csharp
var myScenario = Scenario.Create("my_test", async context =>
{
    var request = Http.CreateRequest("GET", $"{_baseUrl}/api/my-endpoint");
    return await Http.Send(request, context);
})
.WithLoadSimulations(
    Simulation.Inject(rate: 10, interval: TimeSpan.FromSeconds(1), 
                     during: TimeSpan.FromMinutes(1))
);
```

## 🎯 Alternative Tools

### k6 Tests (JavaScript)

```bash
cd k6-scripts

# Basic load test
k6 run basic-load-test.js

# Stress test
k6 run stress-test.js

# Custom URL
k6 run -e BASE_URL=https://api.worknest.com basic-load-test.js
```

### Artillery Tests (YAML)

```bash
# Run Artillery test
artillery run artillery-config.yml

# Generate HTML report
artillery run --output report.json artillery-config.yml
artillery report report.json
```

## 🐛 Troubleshooting

### Issue: Connection Refused

**Solution:**
```bash
# Make sure API is running
cd ../BEWorkNest
dotnet run

# In another terminal, run tests
cd BEWorkNest.LoadTests
dotnet run -- health
```

### Issue: High Error Rate

**Possible causes:**
- API not running
- Database connection issues
- Rate limiting triggered
- Server overloaded

**Solution:**
```bash
# Check API health
curl http://localhost:5000/health

# Check metrics
curl http://localhost:5000/api/metrics

# Reduce load
# Edit appsettings.json, reduce CopiesCount
```

### Issue: Timeouts

**Solution:**
```csharp
// Increase timeout in Program.cs
var request = Http.CreateRequest("GET", url)
    .WithTimeout(TimeSpan.FromSeconds(30)); // Increase from default
```

## 📚 Resources

- **NBomber Docs:** https://nbomber.com/docs/
- **k6 Docs:** https://k6.io/docs/
- **Artillery Docs:** https://www.artillery.io/docs
- **Load Testing Guide:** [LOAD_TESTING_GUIDE.md](LOAD_TESTING_GUIDE.md)

## 🎓 Best Practices

1. **Start small** - Run health check test first
2. **Ramp gradually** - Don't jump to max load immediately
3. **Monitor resources** - Watch CPU, memory, database during tests
4. **Run multiple times** - One test isn't conclusive
5. **Production-like environment** - Test in similar conditions
6. **Baseline first** - Establish baseline before optimizations
7. **Version control** - Track test results over time

## 🤝 Contributing

To add new test scenarios:

1. Add scenario in `Program.cs`
2. Update configuration in `appsettings.json`
3. Document in `LOAD_TESTING_GUIDE.md`
4. Test and validate results

## 📝 License

Part of WorkNest graduation project.

---

**Quick Start:**
```bash
# From workspace root
./run-load-tests.sh

# Select option 8 (All Tests)
# Check reports/ folder for results
```

**Need help?** Check [LOAD_TESTING_GUIDE.md](LOAD_TESTING_GUIDE.md) for detailed documentation.
