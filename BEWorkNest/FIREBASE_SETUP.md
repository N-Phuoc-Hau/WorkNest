# Firebase Setup Guide

## Lỗi hiện tại
Lỗi `System.ArgumentNullException: Value cannot be null. (Parameter 'path')` xảy ra vì:
1. Thiếu cấu hình `ServiceAccountKeyPath` trong `appsettings.json`
2. File `firebase-adminsdk.json` chứa placeholder values thay vì thông tin thực

## Cách khắc phục

### 1. Lấy Firebase Service Account Key
1. Đăng nhập vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project `jobappchat`
3. Vào **Project Settings** (⚙️ icon)
4. Chọn tab **Service accounts**
5. Click **Generate new private key**
6. Tải file JSON về

### 2. Cập nhật file firebase-adminsdk.json
Thay thế nội dung file `firebase-adminsdk.json` bằng thông tin từ file JSON vừa tải về.

### 3. Cấu hình đã được sửa
- ✅ Đã thêm `ServiceAccountKeyPath` vào `appsettings.json`
- ✅ Đã cập nhật `FirebaseService` để xử lý lỗi gracefully
- ✅ Service sẽ không crash nếu Firebase chưa được cấu hình đúng

### 4. Test
Sau khi cập nhật file `firebase-adminsdk.json` với thông tin thực, restart ứng dụng và kiểm tra logs để đảm bảo Firebase được khởi tạo thành công.

## Lưu ý bảo mật
- Không commit file `firebase-adminsdk.json` vào git
- Thêm vào `.gitignore` nếu chưa có
- Sử dụng User Secrets hoặc Environment Variables cho production 