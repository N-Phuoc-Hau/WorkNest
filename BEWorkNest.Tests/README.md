# BEWorkNest.Tests - Unit Tests cho Backend

## 📚 Cấu trúc thư mục

```
BEWorkNest.Tests/
├── Controllers/          # Tests cho Controllers
│   ├── AuthControllerTests.cs
│   ├── JobPostControllerTests.cs
│   └── CompanyControllerTests.cs
├── Services/            # Tests cho Services
│   ├── AuthServiceTests.cs
│   └── JobPostServiceTests.cs
├── Repositories/        # Tests cho Repositories
├── Helpers/             # Test helpers và utilities
└── README.md           # File này
```

## 🧪 Chạy tests

### Chạy tất cả tests
```bash
cd BEWorkNest.Tests
dotnet test
```

### Chạy với code coverage
```bash
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura
```

### Chạy tests cụ thể
```bash
# Chạy 1 test class
dotnet test --filter "FullyQualifiedName~AuthControllerTests"

# Chạy 1 test method
dotnet test --filter "FullyQualifiedName~Login_WithValidCredentials"
```

### Xem coverage report
```bash
dotnet tool install -g dotnet-reportgenerator-globaltool
reportgenerator -reports:"coverage.cobertura.xml" -targetdir:"coverage-report" -reporttypes:Html
```

Mở `coverage-report/index.html` trong trình duyệt.

## 📖 Quy ước đặt tên

### Test Class
- Tên class cần test + "Tests"
- Ví dụ: `AuthController` → `AuthControllerTests`

### Test Method
- Format: `MethodName_Scenario_ExpectedResult`
- Ví dụ: 
  - `Login_WithValidCredentials_ReturnsToken`
  - `GetJobPosts_WhenEmpty_ReturnsEmptyList`
  - `CreateCompany_WithInvalidData_ThrowsException`

## 🎯 Pattern: AAA (Arrange-Act-Assert)

```csharp
[Fact]
public void Login_WithValidCredentials_ReturnsToken()
{
    // Arrange (Chuẩn bị)
    var controller = new AuthController();
    var email = "test@example.com";
    var password = "password123";
    
    // Act (Thực hiện)
    var result = controller.Login(email, password);
    
    // Assert (Kiểm tra)
    result.Should().NotBeNull();
    result.Token.Should().NotBeEmpty();
}
```

## 📊 Coverage Goals

- **Controllers:** ≥ 80%
- **Services:** ≥ 85%
- **Repositories:** ≥ 80%
- **Overall:** ≥ 80%

## 🔧 Tools

- **xUnit:** Testing framework
- **Moq:** Mocking dependencies
- **FluentAssertions:** Readable assertions
- **Coverlet:** Code coverage
