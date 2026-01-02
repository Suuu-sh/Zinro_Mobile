### 1. 依存関係のインストール

```bash
cd Mobile
flutter pub get
```

### 2. バックエンドサーバーの起動

```bash
cd Backend
npm install
npm start
```

### 3. サーバーURLの設定

`Mobile/lib/services/socket_service.dart`の`serverUrl`を変更してください：

```dart
// ローカルネットワークの場合
static const String serverUrl = 'http://192.168.x.x:3000';

// localhost（エミュレータの場合）
static const String serverUrl = 'http://10.0.2.2:3000'; // Android
static const String serverUrl = 'http://localhost:3000'; // iOS
```

### 4. アプリの起動

```bash
flutter run
```