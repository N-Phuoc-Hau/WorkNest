# 💬 Hướng Dẫn Tính Năng Chat trong RecruiterApplicantsScreen

## 🎯 Tổng Quan

Tính năng chat mới được tích hợp vào màn hình quản lý ứng viên của nhà tuyển dụng, cho phép:
- Nhắn tin trực tiếp với ứng viên
- Tạo phòng chat tự động
- Nhận thông báo push khi có tin nhắn mới
- Lưu trữ lịch sử chat trên Firebase Realtime Database

## 🔧 Cài Đặt và Tích Hợp

### 1. Dependencies Cần Thiết

Đảm bảo các package sau đã được thêm vào `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.3.6
  firebase_database: ^10.2.4
  firebase_messaging: ^14.6.5
```

### 2. Imports Cần Thiết

```dart
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../chat/screens/chat_screen.dart';
```

## 📱 Cách Sử Dụng

### 1. Nhắn Tin Trực Tiếp

Người dùng có **2 cách** để bắt đầu cuộc trò chuyện:

#### Cách 1: Nút "Nhắn tin" trên thẻ ứng viên
```dart
ElevatedButton.icon(
  onPressed: () => _startChatWithApplicant(applicant),
  icon: const Icon(Icons.chat_bubble_outline, size: 16),
  label: const Text('Nhắn tin'),
)
```

#### Cách 2: Option trong menu "More" (⋮)
```dart
ListTile(
  leading: const Icon(Icons.message, color: Colors.blue),
  title: const Text('Nhắn tin'),
  onTap: () => _startChatWithApplicant(applicant),
)
```

### 2. Quy Trình Tạo Chat

Khi người dùng nhấn "Nhắn tin":

1. **Hiển thị Loading**: "Đang tạo cuộc trò chuyện..."
2. **Kiểm tra Authentication**: Đảm bảo người dùng đã đăng nhập
3. **Chuẩn bị Data**: Thu thập thông tin recruiter, candidate, job
4. **Tạo Chat Room**: Sử dụng ChatProvider để tạo/lấy room
5. **Chuyển hướng**: Navigate đến ChatScreen
6. **Thông báo**: Hiển thị success message

## 🔧 API và Data Structure

### 1. Chat Room ID Generation

```dart
String generateChatRoomId(String recruiterId, String candidateId, String? jobId) {
  final sortedIds = [recruiterId, candidateId]..sort();
  return jobId != null ? 
    '${sortedIds[0]}_${sortedIds[1]}_$jobId' :
    '${sortedIds[0]}_${sortedIds[1]}';
}
```

### 2. User Info Structure

```dart
// Recruiter Info
{
  'id': currentUser.id,
  'name': '${currentUser.firstName} ${currentUser.lastName}'.trim(),
  'email': currentUser.email,
  'avatar': currentUser.avatar,
  'role': currentUser.role,
}

// Candidate Info
{
  'id': applicant.applicantId,
  'name': applicant.applicantName,
  'email': applicant.applicant?.email ?? '',
  'avatar': applicant.applicant?.avatar,
  'role': 'candidate',
}

// Job Info
{
  'id': applicant.jobId.toString(),
  'title': applicant.job?.title ?? 'Không rõ',
  'company': applicant.job?.recruiter.company?.name ?? 'Không rõ',
}
```

## 🛠️ Backend Integration

### 1. Firebase Service cho Push Notifications

```csharp
public async Task<string> SendChatNotificationAsync(
    string fcmToken, 
    string senderName, 
    string message, 
    string chatRoomId, 
    Dictionary<string, string>? additionalData = null)
```

### 2. Notification Structure

```csharp
var data = new Dictionary<string, string>
{
    ["type"] = "chat",
    ["chatRoomId"] = chatRoomId,
    ["senderName"] = senderName,
    ["message"] = message
};
```

## 🎨 UI/UX Features

### 1. Loading States

- **LoadingDialog**: Hiển thị khi đang tạo chat room
- **Custom Message**: "Đang tạo cuộc trò chuyện..."
- **Non-dismissible**: Không thể đóng khi đang xử lý

### 2. Notification System

- **Success**: Màu xanh với icon check
- **Error**: Màu đỏ với icon error
- **Floating**: SnackBar style floating
- **Auto-dismiss**: Tự động ẩn sau vài giây

### 3. Button Styling

```dart
ElevatedButton.styleFrom(
  backgroundColor: Colors.green,
  foregroundColor: Colors.white,
)
```

## 🔍 Error Handling

### 1. Authentication Errors

```dart
if (authState.user == null) {
  LoadingDialog.hide(context);
  NotificationHelper.showError(
    context, 
    'Vui lòng đăng nhập để sử dụng tính năng này'
  );
  return;
}
```

### 2. Network/Firebase Errors

```dart
} catch (e) {
  LoadingDialog.hide(context);
  NotificationHelper.showError(
    context,
    'Lỗi khi tạo cuộc trò chuyện: ${e.toString()}',
  );
}
```

## 📊 Performance Considerations

### 1. Efficient Data Loading

- Chỉ load data khi cần thiết
- Cache user info để tránh multiple API calls
- Sử dụng Riverpod để manage state efficiently

### 2. Memory Management

- Dispose controllers properly
- Clear unused chat listeners
- Optimize Firebase queries

## 🧪 Testing

### 1. Unit Tests

```dart
// Test chat room ID generation
test('should generate consistent chat room ID', () {
  final roomId = generateChatRoomId('user1', 'user2', 'job123');
  expect(roomId, equals('user1_user2_job123'));
});
```

### 2. Integration Tests

- Test chat creation flow
- Verify navigation to ChatScreen
- Check error handling scenarios

## 🔐 Security Considerations

### 1. User Authentication

- Kiểm tra authentication state trước khi tạo chat
- Validate user permissions
- Secure Firebase rules

### 2. Data Privacy

- Chỉ share thông tin cần thiết
- Encrypt sensitive data
- Follow GDPR guidelines

## 🚀 Deployment Notes

### 1. Firebase Configuration

- Đảm bảo Firebase projects được cấu hình đúng
- Set up proper security rules
- Configure push notification certificates

### 2. Environment Variables

- FCM server keys
- Database URLs
- Authentication configs

## 📝 Changelog

### Version 1.0.0
- ✅ Basic chat integration
- ✅ Push notifications
- ✅ Error handling
- ✅ Loading states

### Future Enhancements
- 🔄 File sharing in chat
- 🔄 Read receipts
- 🔄 Typing indicators
- 🔄 Message reactions

## 💡 Tips và Best Practices

1. **Always handle loading states** để UX tốt hơn
2. **Implement proper error handling** để tránh crash
3. **Use consistent naming conventions** cho maintainability
4. **Test on different devices** để đảm bảo compatibility
5. **Monitor Firebase usage** để tối ưu cost

---

**Tác giả**: GitHub Copilot  
**Cập nhật lần cuối**: August 7, 2025
