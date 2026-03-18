using NBomber.CSharp;
using NBomber.Http.CSharp;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;

namespace BEWorkNest.LoadTests;

public class Program
{
    private static IConfiguration _configuration = null!;
    private static string _baseUrl = null!;
    private static HttpClient _httpClient = new HttpClient();

    public static void Main(string[] args)
    {
        LoadConfiguration();

        Console.WriteLine("╔═══════════════════════════════════════════════════════════════╗");
        Console.WriteLine("║         WorkNest API - Load Testing Suite v1.0              ║");
        Console.WriteLine("╚═══════════════════════════════════════════════════════════════╝");
        Console.WriteLine();
        Console.WriteLine($"Target URL: {_baseUrl}");
        Console.WriteLine();

        // Run different test scenarios
        var testMode = args.Length > 0 ? args[0] : "all";

        switch (testMode.ToLower())
        {
            case "health":
                RunHealthCheckTest();
                break;
            case "auth":
                RunAuthenticationTest();
                break;
            case "jobs":
                RunJobPostsTest();
                break;
            case "search":
                RunSearchTest();
                break;
            case "stress":
                RunStressTest();
                break;
            case "spike":
                RunSpikeTest();
                break;
            case "endurance":
                RunEnduranceTest();
                break;
            case "all":
            default:
                RunAllTests();
                break;
        }
    }

    private static void LoadConfiguration()
    {
        _configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
            .Build();

        _baseUrl = _configuration["LoadTest:BaseUrl"] ?? "http://localhost:5006";
    }

    private static void RunHealthCheckTest()
    {
        Console.WriteLine("🏥 Running Health Check Test...\n");

        var scenario = Scenario.Create("health_check", async context =>
        {
            var request = Http.CreateRequest("GET", $"{_baseUrl}/health")
                .WithHeader("Accept", "application/json");

            var response = await Http.Send(_httpClient, request);
            return response;
        })
        .WithWarmUpDuration(TimeSpan.FromSeconds(5))
        .WithLoadSimulations(
            Simulation.Inject(rate: 10, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30))
        );

        NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
    }

    private static void RunAuthenticationTest()
    {
        Console.WriteLine("🔐 Running Authentication Test...\n");

        var scenario = Scenario.Create("authentication_load", async context =>
        {
            var loginData = new
            {
                email = "loadtest@example.com",
                password = "Test@123"
            };

            var request = Http.CreateRequest("POST", $"{_baseUrl}/api/auth/login")
                .WithHeader("Content-Type", "application/json")
                .WithBody(new StringContent(JsonConvert.SerializeObject(loginData)));

            var response = await Http.Send(_httpClient, request);
            return response;
        })
        .WithWarmUpDuration(TimeSpan.FromSeconds(5))
        .WithLoadSimulations(
            Simulation.Inject(rate: 5, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30)),
            Simulation.InjectRandom(minRate: 5, maxRate: 20, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30))
        );

        NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
    }

    private static void RunJobPostsTest()
    {
        Console.WriteLine("💼 Running Job Posts Test...\n");

        var scenario = Scenario.Create("job_posts", async context =>
        {
            // Get job posts list
            var request = Http.CreateRequest("GET", $"{_baseUrl}/api/jobpost?page=1&pageSize=10")
                .WithHeader("Accept", "application/json");

            var response = await Http.Send(_httpClient, request);
            return response;
        })
        .WithWarmUpDuration(TimeSpan.FromSeconds(5))
        .WithLoadSimulations(
            Simulation.RampingInject(rate: 10, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(20)),
            Simulation.Inject(rate: 20, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(40)),
            Simulation.RampingInject(rate: 0, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(10))
        );

        NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
    }

    private static void RunSearchTest()
    {
        Console.WriteLine("🔍 Running Search Test...\n");

        var searchKeywords = new[] { "developer", "designer", "manager", "engineer", "analyst" };

        var scenario = Scenario.Create("search", async context =>
        {
            var keyword = searchKeywords[Random.Shared.Next(searchKeywords.Length)];
            var request = Http.CreateRequest("GET", $"{_baseUrl}/api/search/jobs?keyword={keyword}&page=1&pageSize=10")
                .WithHeader("Accept", "application/json");

            var response = await Http.Send(_httpClient, request);
            return response;
        })
        .WithWarmUpDuration(TimeSpan.FromSeconds(5))
        .WithLoadSimulations(
            Simulation.Inject(rate: 15, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(60))
        );

        NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
    }

    private static void RunStressTest()
    {
        Console.WriteLine("💪 Running Stress Test - Finding Breaking Point...\n");

        var scenario = Scenario.Create("stress_test", async context =>
        {
            var request = Http.CreateRequest("GET", $"{_baseUrl}/api/jobpost?page=1&pageSize=20")
                .WithHeader("Accept", "application/json");

            var response = await Http.Send(_httpClient, request);
            return response;
        })
        .WithWarmUpDuration(TimeSpan.FromSeconds(10))
        .WithLoadSimulations(
            Simulation.RampingInject(rate: 10, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30)),
            Simulation.RampingInject(rate: 50, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30)),
            Simulation.RampingInject(rate: 100, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(30)),
            Simulation.Inject(rate: 100, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(60)),
            Simulation.RampingInject(rate: 0, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(20))
        );

        NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
    }

    private static void RunSpikeTest()
    {
        Console.WriteLine("⚡ Running Spike Test - Sudden Traffic Burst...\n");

        var scenario = Scenario.Create("spike_test", async context =>
        {
            var request = Http.CreateRequest("GET", $"{_baseUrl}/health")
                .WithHeader("Accept", "application/json");

            var response = await Http.Send(_httpClient, request);
            return response;
        })
        .WithWarmUpDuration(TimeSpan.FromSeconds(5))
        .WithLoadSimulations(
            Simulation.Inject(rate: 5, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(20)),
            Simulation.Inject(rate: 100, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(10)), // SPIKE
            Simulation.Inject(rate: 5, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromSeconds(20))
        );

        NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
    }

    private static void RunEnduranceTest()
    {
        Console.WriteLine("⏱️  Running Endurance Test - 10 Minutes Sustained Load...\n");
        Console.WriteLine("This will take approximately 10 minutes...\n");

        var scenario = Scenario.Create("endurance_test", async context =>
        {
            var endpoints = new[]
            {
                "/health",
                "/api/jobpost?page=1&pageSize=10",
                "/api/search?keyword=developer"
            };

            var endpoint = endpoints[Random.Shared.Next(endpoints.Length)];
            var request = Http.CreateRequest("GET", $"{_baseUrl}{endpoint}")
                .WithHeader("Accept", "application/json");

            var response = await Http.Send(_httpClient, request);
            return response;
        })
        .WithWarmUpDuration(TimeSpan.FromSeconds(10))
        .WithLoadSimulations(
            Simulation.Inject(rate: 30, interval: TimeSpan.FromSeconds(1), during: TimeSpan.FromMinutes(10))
        );

        NBomberRunner
            .RegisterScenarios(scenario)
            .Run();
    }

    private static void RunAllTests()
    {
        Console.WriteLine("╔═══════════════════════════════════════════════════════════════╗");
        Console.WriteLine("║       🚀 RUNNING ALL LOAD TESTS - COMPREHENSIVE SUITE       ║");
        Console.WriteLine("╚═══════════════════════════════════════════════════════════════╝");
        Console.WriteLine();
        Console.WriteLine("⏱️  Estimated Total Duration: ~15-20 minutes");
        Console.WriteLine();
        Console.WriteLine("Tests to run:");
        Console.WriteLine("  1️⃣  Health Check Test (30s)");
        Console.WriteLine("  2️⃣  Authentication Test (1 min)");
        Console.WriteLine("  3️⃣  Job Posts Test (1 min)");
        Console.WriteLine("  4️⃣  Search Test (1 min)");
        Console.WriteLine("  5️⃣  Stress Test (3 min)");
        Console.WriteLine("  6️⃣  Spike Test (1 min)");
        Console.WriteLine("  7️⃣  Endurance Test (10 min)");
        Console.WriteLine();
        Console.WriteLine("Starting tests in 3 seconds...");
        Console.WriteLine("═══════════════════════════════════════════════════════════════");
        Thread.Sleep(3000);

        try
        {
            // Test 1: Health Check
            Console.WriteLine("\n\n[1/7] ═══════════════════════════════════════════════════════");
            RunHealthCheckTest();
            Console.WriteLine("✅ Health Check Test completed!");
            Thread.Sleep(2000);

            // Test 2: Authentication
            Console.WriteLine("\n\n[2/7] ═══════════════════════════════════════════════════════");
            RunAuthenticationTest();
            Console.WriteLine("✅ Authentication Test completed!");
            Thread.Sleep(2000);

            // Test 3: Job Posts
            Console.WriteLine("\n\n[3/7] ═══════════════════════════════════════════════════════");
            RunJobPostsTest();
            Console.WriteLine("✅ Job Posts Test completed!");
            Thread.Sleep(2000);

            // Test 4: Search
            Console.WriteLine("\n\n[4/7] ═══════════════════════════════════════════════════════");
            RunSearchTest();
            Console.WriteLine("✅ Search Test completed!");
            Thread.Sleep(2000);

            // Test 5: Stress Test
            Console.WriteLine("\n\n[5/7] ═══════════════════════════════════════════════════════");
            RunStressTest();
            Console.WriteLine("✅ Stress Test completed!");
            Thread.Sleep(2000);

            // Test 6: Spike Test
            Console.WriteLine("\n\n[6/7] ═══════════════════════════════════════════════════════");
            RunSpikeTest();
            Console.WriteLine("✅ Spike Test completed!");
            Thread.Sleep(2000);

            // Test 7: Endurance Test
            Console.WriteLine("\n\n[7/7] ═══════════════════════════════════════════════════════");
            RunEnduranceTest();
            Console.WriteLine("✅ Endurance Test completed!");

            // Final Summary
            Console.WriteLine("\n\n╔═══════════════════════════════════════════════════════════════╗");
            Console.WriteLine("║                  ✅ ALL TESTS COMPLETED!                     ║");
            Console.WriteLine("╚═══════════════════════════════════════════════════════════════╝");
            Console.WriteLine();
            Console.WriteLine("📊 Test Summary:");
            Console.WriteLine("  ✅ Health Check Test");
            Console.WriteLine("  ✅ Authentication Test");
            Console.WriteLine("  ✅ Job Posts Test");
            Console.WriteLine("  ✅ Search Test");
            Console.WriteLine("  ✅ Stress Test");
            Console.WriteLine("  ✅ Spike Test");
            Console.WriteLine("  ✅ Endurance Test");
            Console.WriteLine();
            Console.WriteLine("📁 Reports saved in: ./reports/");
            Console.WriteLine("📈 Open HTML reports in your browser for detailed analysis");
            Console.WriteLine();
            Console.WriteLine("═══════════════════════════════════════════════════════════════");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"\n❌ Error during test execution: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
            throw;
        }
    }
}
