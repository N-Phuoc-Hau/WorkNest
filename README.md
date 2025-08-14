# 🏢 WorkNest - Nền tảng Tuyển dụng Thông minh

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/.NET-512BD4?style=for-the-badge&logo=dotnet&logoColor=white" />
  <img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
</div>

## 📖 Giới thiệu

**WorkNest** là một nền tảng tuyển dụng hiện đại và thông minh, được thiết kế để kết nối ứng viên và nhà tuyển dụng một cách hiệu quả nhất. Ứng dụng cung cấp trải nghiệm tuyển dụng toàn diện với giao diện thân thiện và các tính năng tiên tiến.

### 🎯 Mục tiêu
- Tạo cầu nối hiệu quả giữa ứng viên và nhà tuyển dụng
- Đơn giản hóa quy trình tuyển dụng và ứng tuyển
- Cung cấp công cụ quản lý ứng viên và công việc thông minh
- Xây dựng cộng đồng tuyển dụng chuyên nghiệp

## ✨ Tính năng chính

### 👤 Cho Ứng viên (Candidate)
- **🔍 Tìm kiếm công việc thông minh**: Tìm kiếm theo vị trí, lương, kinh nghiệm
- **📄 Hồ sơ cá nhân**: Tạo và quản lý CV trực tuyến
- **💼 Ứng tuyển nhanh**: Apply công việc với 1 click
- **⭐ Yêu thích & Theo dõi**: Lưu công việc và theo dõi công ty
- **💬 Chat trực tiếp**: Trao đổi với nhà tuyển dụng
- **🔔 Thông báo thông minh**: Cập nhật trạng thái ứng tuyển
- **📊 Dashboard cá nhân**: Theo dõi tiến trình ứng tuyển
- **🌟 Đánh giá công ty**: Chia sẻ trải nghiệm làm việc

### 🏢 Cho Nhà tuyển dụng (Recruiter)
- **📝 Đăng tin tuyển dụng**: Tạo và quản lý bài đăng tuyển dụng
- **👥 Quản lý ứng viên**: Xem, lọc và đánh giá hồ sơ ứng viên
- **🔄 Quy trình tuyển dụng**: Theo dõi từng giai đoạn tuyển dụng
- **📈 Thống kê tuyển dụng**: Phân tích hiệu quả tuyển dụng
- **💬 Chat với ứng viên**: Tương tác trực tiếp
- **🏢 Quản lý công ty**: Cập nhật thông tin và hình ảnh công ty
- **🎯 Gợi ý ứng viên**: AI đề xuất ứng viên phù hợp

### 🛠️ Cho Admin
- **📊 Dashboard tổng quan**: Thống kê toàn hệ thống
- **👨‍💼 Quản lý người dùng**: Quản lý tài khoản và phân quyền
- **🏢 Quản lý công ty**: Xét duyệt và quản lý doanh nghiệp
- **📈 Phân tích dữ liệu**: Báo cáo chi tiết về hoạt động

## 🏗️ Kiến trúc hệ thống

### Frontend (Flutter)
```
lib/
├── core/                    # Core functionality
│   ├── models/             # Data models
│   ├── providers/          # State management (Riverpod)
│   ├── services/           # API services
│   ├── utils/              # Utilities
│   └── constants/          # Constants
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── jobs/              # Job management
│   ├── profile/           # User profiles
│   ├── chat/              # Real-time chat
│   ├── reviews/           # Company reviews
│   ├── applications/      # Job applications
│   ├── dashboard/         # Analytics dashboard
│   └── ...
└── shared/                # Shared components
```

### Backend (ASP.NET Core)
```
BEWorkNest/
├── Controllers/           # API controllers
├── Models/               # Data models & DTOs
├── Services/             # Business logic
├── Data/                 # Database context
├── Authorization/        # Auth handlers
└── Migrations/           # Database migrations
```

## 🛠️ Công nghệ sử dụng

### Frontend
- **Flutter**: Framework cross-platform
- **Riverpod**: State management
- **Go Router**: Navigation
- **Dio**: HTTP client
- **Firebase**: Push notifications

### Backend  
- **ASP.NET Core 8**: Web API framework
- **Entity Framework Core**: ORM
- **MySQL**: Primary database
- **Firebase**: Real-time database & notifications
- **JWT**: Authentication
- **Cloudinary**: Image storage
- **SignalR**: Real-time communication

### DevOps & Tools
- **Git**: Version control
- **Swagger**: API documentation
- **Postman**: API testing

## 🚀 Cài đặt và Chạy ứng dụng

### Yêu cầu hệ thống
- **Flutter SDK**: >= 3.6.0
- **.NET SDK**: >= 8.0
- **MySQL**: >= 8.0
- **Visual Studio Code** hoặc **Android Studio**

### Backend Setup
```bash
# Clone repository
git clone https://github.com/N-Phuoc-Hau/WorkNest.git
cd WorkNest/BEWorkNest

# Restore packages
dotnet restore

# Update database
dotnet ef database update

# Run application
dotnet run
```

### Frontend Setup
```bash
# Navigate to Flutter project
cd ../feworknest

# Install dependencies
flutter pub get

# Run application
flutter run
```

### Cấu hình Database
```json
// appsettings.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=worknest;Uid=root;Pwd=your_password;"
  },
  "Jwt": {
    "Key": "your-secret-key",
    "Issuer": "WorkNest",
    "Audience": "WorkNest-Users"
  }
}
```

## 📱 Screenshots

### Mobile App
| Login | Job Search | Job Details | Profile |
|-------|------------|-------------|---------|
| ![Login](screenshots/login.png) | ![Search](screenshots/search.png) | ![Details](screenshots/details.png) | ![Profile](screenshots/profile.png) |

### Dashboard
| Candidate Dashboard | Recruiter Dashboard | Admin Dashboard |
|-------------------|-------------------|-----------------|
| ![Candidate](screenshots/candidate-dash.png) | ![Recruiter](screenshots/recruiter-dash.png) | ![Admin](screenshots/admin-dash.png) |

## 🔐 API Documentation

API documentation có sẵn tại: `http://localhost:5000/swagger`

### Các endpoint chính:
- **Auth**: `/api/Auth/*` - Authentication & Authorization
- **Jobs**: `/api/JobPost/*` - Job management
- **Applications**: `/api/Application/*` - Application management
- **Users**: `/api/User/*` - User management
- **Chat**: `/api/Chat/*` - Real-time messaging
- **Reviews**: `/api/Review/*` - Company reviews

## 👥 Đóng góp

Chúng tôi hoan nghênh mọi đóng góp! Để đóng góp:

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## 📋 Roadmap

- [ ] **v2.0**: AI-powered job matching
- [ ] **v2.1**: Video interview integration  
- [ ] **v2.2**: Skills assessment tests
- [ ] **v2.3**: Company culture insights
- [ ] **v2.4**: Salary benchmarking
- [ ] **v2.5**: Mobile app optimization

## 🐛 Báo lỗi

Nếu bạn gặp lỗi, vui lòng tạo issue tại [GitHub Issues](https://github.com/N-Phuoc-Hau/WorkNest/issues)

## 📄 License

Dự án này được phát hành dưới [MIT License](LICENSE)

## 👨‍💻 Tác giả

**N-Phuoc-Hau**
- GitHub: [@N-Phuoc-Hau](https://github.com/N-Phuoc-Hau)
- Email: your-email@example.com

## 🙏 Lời cảm ơn

- Flutter team cho framework tuyệt vời
- Microsoft cho ASP.NET Core
- Firebase cho các service real-time
- Cộng đồng open source

---

<div align="center">
  <p>Made with ❤️ in Vietnam</p>
  <p>© 2024 WorkNest. All rights reserved.</p>
</div>
