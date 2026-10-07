Sen tajribali Flutter arxitektori va Nuxt.js developerisan.
Quyidagi Nuxt.js kodini Flutter ga ko'chir.

Faqat XODIMLAR uchun 2 ta ekran kerak:
1. Login ekrani
2. Dashboard + Face Liveness ekrani

═══════════════════════════════════════
🔑 AUTH — LOGIN
═══════════════════════════════════════

Endpoint: POST https://api.visionhr.uz/api/v1/auth/login
Request:  { "login": "string", "password": "string" }
Response: { "data": { "token": "xxx", "user": {...} } }

Token flutter_secure_storage ga saqlansin.
Login bo'lgandan keyin → DashboardScreen ga yo'naltir.
Token bo'lsa → splash da tekshirib DashboardScreen ga o't.

Flutter Login UI:
- Logo (assets/images/logo.png)
- "VISION HR" sarlavha (Manrope font, bold)
- Login input (TextFormField, prefixIcon: person)
- Password input (obscureText, toggle ko'rish)
- "Kirish" tugmasi (to'liq kenglik, gradient: 0xFF2D4ADD)
- Loading holati (CircularProgressIndicator)
- Xato bo'lsa SnackBar bilan ko'rsat

═══════════════════════════════════════
📱 DASHBOARD — XODIM EKRANI
═══════════════════════════════════════

Nuxtdagi bu API larni Flutter ga ko'chir:

  GET /auth/me?relations=role
  GET /settings/users/:id?relations=locations|todayWorkDay|location|warehouse|employeeSchedule
  GET /hr/in-outs?user_id=&from_date=&to_date=   ← bugungi sana

Dashboard UI (yuqoridan pastga scroll):

  1. AppBar:
     - Chap: Logo + "VISION HR"
     - O'ng: Foydalanuvchi ismi + Logout icon

  2. User Card:
     - Avatar (CircleAvatar, network image)
     - Ism, Rol
     - Ish joyi (locations yoki location.name)
     - Ish grafigi (start_time - end_time)

  3. Ish Holati Card:
     - Badge: "Ishlamoqda" (yashil) yoki "Ishga kelmagan" (kulrang)
     - Agar kech qolgan bo'lsa: sariq Alert ("Siz X daqiqa kech qoldingiz")
     - Agar erta kelgan bo'lsa: ko'k Alert ("Ish boshlanishiga X daqiqa qoldi")
     - Agar bugun dam olish / bayram: tegishli Alert
     - Asosiy tugma:
         on_work_status != 1 → "ISHNI BOSHLASH" (ko'k gradient)
         on_work_status == 1 → "ISHNI YAKUNLASH" (qizil gradient)
         disabled: on_work_status != 1 && isPastEndTime && !isOff

  4. Statistika:
     - "Birinchi kelish" vaqti (bugungi birinchi type="in")
     - "Oxirgi ketish" vaqti (bugungi oxirgi type="out")

  5. Bugungi faollik ro'yxati:
     - ListView: Turi (KIRISH/CHIQISH), Vaqt, Rasm (thumbnail), Izoh
     - Rasm bosilganda fullscreen dialog ochilsin

═══════════════════════════════════════
📍 GPS TEKSHIRISH LOGIKASI
═══════════════════════════════════════

Tugma bosilganda:
1. geolocator bilan GPS koordinata ol
2. Har bir filial uchun Haversine formula bilan masofa hisobla:

   double haversine(lat1, lon1, lat2, lon2) {
     const R = 6371000; // metr
     // standart formula
   }

3. loc.location "lat,lon" string bo'lsa → parse qil
   Aks holda loc.latitude / loc.longitude ishlat
   Agar latitude > 90 → lat va lon ni almashtir (swap)

4. default radius = 250 metr (loc.radius bo'lmasa)

5. Radius ichida → activeLocationId saqla → LivenessScreen och
   Tashqarida → SnackBar: "Siz eng yaqin filialdan X metr uzoqlikdasiz"

6. GPS ruxsat yo'q (PermissionStatus.denied / permanentlyDenied):
   → PermissionGuideDialog ko'rsat

═══════════════════════════════════════
📷 FACE LIVENESS CHECK
═══════════════════════════════════════

GPS OK bo'lgandan keyin LivenessScreen ochilsin (showModalBottomSheet yoki push).

Liveness oqimi:
  1. camera paketi bilan old kamera ochilsin
  2. google_mlkit_face_detection bilan real-time yuz aniqla
  3. Yuz to'g'ri joylashganda (faceCount >= 1, bounds markazda):
     - Avtomatik rasm ol (takePicture)
     - JPEG 80% sifat → base64 ga convert qil
  4. POST https://api.visionhr.uz/api/v1/hr/in-outs ga yubor:
     {
       "type": "in" yoki "out",   ← on_work_status asosida
       "location_id": activeLocationId,
       "photo": "base64string",
       "comment": null
     }
  5. Muvaffaqiyatli → modal yopilsin → Dashboard refresh
  6. Xato → SnackBar bilan xabar

Kamera UI overlay:
  - Markazda oval/ellipse ramka (gestured dashed border, ko'k)
  - "Yuzingizni ramka ichiga joylashtiring" matni
  - Yuqorida X (yopish) tugmasi

Kamera ruxsati yo'q:
  → PermissionGuideDialog ko'rsat (kamera turi bilan)

═══════════════════════════════════════
🔔 PERMISSION GUIDE DIALOG
═══════════════════════════════════════

showDialog bilan chiqsin. Kontent:

  - Qizil qalqon icon
  - "Kamera/Lokatsiya ruxsati bloklangan" sarlavha
  - Qo'llanma matni:
      Android: Sozlamalar → Ilovalar → Vision HR → Ruxsatlar
      iOS:     Sozlamalar → Vision HR → Ruxsat berish
  - "Sozlamalarga o'tish" tugmasi → openAppSettings()
  - "Yopish" tugmasi

═══════════════════════════════════════
🎨 DIZAYN TOKENLAR
═══════════════════════════════════════

const primary    = Color(0xFF2D4ADD);
const surface    = Color(0xFFF9F9FF);
const onSurface  = Color(0xFF1A1C2E);
const secondary  = Color(0xFF6B7280);
const primaryFixed = Color(0xFFE8ECFF);
const error      = Color(0xFFE11D48);
const success    = Color(0xFF22C55E);
const warning    = Color(0xFFF59E0B);

BorderRadius: 16px (card), 12px (button)
BoxShadow: 0 2px 12px rgba(0,0,0,0.06)
Fontlar: Google Fonts → Inter + Manrope

═══════════════════════════════════════
📁 FAYL STRUKTURASI
═══════════════════════════════════════

lib/
├── main.dart
├── core/
│   ├── constants/api_constants.dart
│   ├── constants/app_colors.dart
│   ├── network/dio_client.dart          ← Bearer token interceptor
│   └── utils/
│       ├── haversine_util.dart
│       └── permission_helper.dart
├── features/
│   ├── auth/
│   │   ├── models/user_model.dart
│   │   ├── repository/auth_repository.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       └── login_provider.dart      ← Riverpod StateNotifier
│   └── dashboard/
│       ├── models/inout_model.dart
│       ├── repository/dashboard_repository.dart
│       └── presentation/
│           ├── dashboard_screen.dart
│           ├── dashboard_provider.dart
│           ├── widgets/
│           │   ├── user_card.dart
│           │   ├── action_card.dart
│           │   ├── stats_row.dart
│           │   └── inout_list.dart
│           └── liveness/
│               ├── liveness_screen.dart
│               └── liveness_provider.dart
└── shared/
    ├── widgets/
    │   ├── app_button.dart
    │   ├── app_alert.dart
    │   └── permission_guide_dialog.dart
    └── theme/app_theme.dart

═══════════════════════════════════════
📦 pubspec.yaml PAKETLAR
═══════════════════════════════════════

dependencies:
  flutter_riverpod: ^2.5.0
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.2
  camera: ^0.11.0
  google_mlkit_face_detection: ^0.11.0
  geolocator: ^13.0.2
  permission_handler: ^11.3.1
  cached_network_image: ^3.4.1
  google_fonts: ^6.2.1
  fluttertoast: ^8.2.8
  intl: ^0.19.0

═══════════════════════════════════════
📋 YOZISH TARTIBI
═══════════════════════════════════════

Quyidagi tartibda to'liq Dart kodi yoz:

1. pubspec.yaml
2. app_colors.dart + app_theme.dart
3. dio_client.dart (Bearer token + 401 interceptor)
4. user_model.dart + inout_model.dart (fromJson/toJson)
5. auth_repository.dart + login_provider.dart + login_screen.dart
6. haversine_util.dart + permission_helper.dart
7. dashboard_repository.dart + dashboard_provider.dart
8. user_card.dart + action_card.dart + stats_row.dart + inout_list.dart
9. liveness_screen.dart + liveness_provider.dart
10. permission_guide_dialog.dart
11. dashboard_screen.dart (barchasini birlashtiradi)
12. main.dart (ProviderScope, GoRouter: /login → /dashboard)

Qoidalar:
- Null safety to'liq
- Riverpod StateNotifier pattern
- O'zbek matnlar saqlansin
- Har metodga // izoh
- Dart best practices