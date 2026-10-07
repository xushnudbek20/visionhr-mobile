# Vision HR — App Store'ga joylash qo'llanmasi

App: **Vision HR** · Bundle ID: `uz.visionhr.mobile` · Min iOS: **15.5** · Faqat iPhone, portret rejim

---

## 1. Kodda allaqachon bajarilgan

| Nima | Holat |
|---|---|
| Bundle ID `com.example.hrMobile` → `uz.visionhr.mobile` | ✅ |
| Ilova nomi "Hr Mobile" → "Vision HR" | ✅ |
| Min iOS 13.0 → 15.5 (ML Kit talabi) | ✅ |
| iPad qo'llab-quvvatlashi olib tashlandi (`TARGETED_DEVICE_FAMILY = 1`) | ✅ |
| Faqat portret rejim | ✅ |
| Kamera/joylashuv ruxsat matnlari aniq va ikki tilda | ✅ |
| Ishlatilmaydigan `NSPhotoLibraryUsageDescription` olib tashlandi | ✅ |
| `permission_handler` faqat kamera+joylashuv bilan kompilyatsiya qilinadi (Podfile) | ✅ |
| `PrivacyInfo.xcprivacy` (privacy manifest) yaratildi va Xcode'ga qo'shildi | ✅ |
| `ITSAppUsesNonExemptEncryption = false` (eksport savoli avtomatik javob) | ✅ |
| App Store ikonkasidan alfa-kanal olib tashlandi | ✅ |
| Launch ekran logotip bilan to'ldirildi | ✅ |
| Release build sinovdan o'tdi (`flutter build ios --release --no-codesign`) | ✅ |

---

## 2. Siz bajarishingiz kerak

### 2.1. Apple Developer hisobi

1. [developer.apple.com](https://developer.apple.com/programs/) — **Apple Developer Program**, yiliga $99.
   Kompaniya nomidan ro'yxatdan o'tish uchun **D-U-N-S raqami** kerak (olish 1–2 hafta ketishi mumkin — oldindan boshlang).
2. Ro'yxatdan o'tgach **Team ID** ni oling (Membership sahifasida).

### 2.2. Xcode'da imzolash (signing)

```bash
open ios/Runner.xcworkspace
```

`Runner` target → **Signing & Capabilities**:
- ✅ Automatically manage signing
- **Team**: kompaniya hisobingizni tanlang
- **Bundle Identifier**: `uz.visionhr.mobile` (allaqachon o'rnatilgan)

Xcode provisioning profilni o'zi yaratadi.

### 2.3. App Store Connect'da ilova yaratish

[appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → **+** → New App:

| Maydon | Qiymat |
|---|---|
| Platform | iOS |
| Name | Vision HR (App Store'da ko'rinadigan nom, 30 belgigacha) |
| Primary Language | Uzbek yoki Russian |
| Bundle ID | `uz.visionhr.mobile` |
| SKU | `visionhr-mobile-001` (ixtiyoriy, ichki ID) |

### 2.4. Build yuklash

```bash
flutter build ipa --release
```

Natija: `build/ios/ipa/hr_mobile.ipa`

Yuklash usullari:
- **Transporter** ilovasi (Mac App Store'dan bepul) — .ipa faylni sudrab tashlang, eng oson yo'l
- yoki Xcode → Product → Archive → Distribute App

Yuklangach build App Store Connect'da 10–30 daqiqada paydo bo'ladi.

---

## 3. App Store Connect metadatasi (rad etilmaslik uchun muhim)

### 3.1. ⚠️ Demo hisob — MAJBURIY

Ilova login talab qiladi. Reviewer kira olmasa **Guideline 2.1 bo'yicha 100% rad etiladi**.

App Review Information bo'limida:
- **Sign-in required**: ✅ belgilang
- **Username / Password**: ishlaydigan test xodim hisobi
- **Notes** ga yozing (ingliz tilida):

> This is an employee attendance app for companies using the Vision HR system.
> Employees check in and out of work by scanning their face with the front camera.
>
> Test account: login `demo` / password `demo1234`
>
> IMPORTANT — how to test the check-in flow:
> The check-in button requires the device to be near a registered office location.
> The test account is bound to a location at coordinates 41.3111, 69.2797 (Tashkent).
> Please simulate this location on the test device (Xcode → Debug → Simulate Location,
> or Settings → Developer → Location), otherwise the check-in button will report
> that you are too far from any office.
>
> Accounts are created by the employer's HR administrator inside the Vision HR web
> panel; users cannot register from within the app.

> ⚠️ Yuqoridagi koordinata va demo login/parolni **haqiqiy ishlaydigan qiymatlarga almashtiring**.
> Reviewer joylashuvni simulyatsiya qila olmasa, davomat tugmasi ishlamaydi va ilova rad etiladi.
> Iloji bo'lsa, demo hisob uchun backend'da masofa tekshiruvini o'chirib qo'ying.

### 3.2. Privacy Policy URL — MAJBURIY

Yuz tasviri va joylashuv yig'ilgani uchun maxfiylik siyosati **shart**. Masalan `https://visionhr.uz/privacy` sahifasini yarating va unda quyidagilar bo'lsin:

- Qanday ma'lumot yig'iladi: yuz fotosurati, joylashuv, ism, xodim ID
- Nima uchun: ish vaqtini qayd etish (davomat)
- Kim ko'radi: faqat xodimning ish beruvchisi (HR administratorlari)
- Qancha saqlanadi va qanday o'chiriladi
- Uchinchi tomonlarga sotilmasligi
- Aloqa uchun email

### 3.3. App Privacy (ma'lumot yig'ish anketasi)

App Store Connect → App Privacy. Quyidagilarni belgilang (kodda yaratilgan `PrivacyInfo.xcprivacy` bilan mos):

| Ma'lumot turi | Maqsad | Shaxsga bog'liqmi | Tracking |
|---|---|---|---|
| Photos or Videos (yuz surati) | App Functionality | Ha | Yo'q |
| Precise Location | App Functionality | Ha | Yo'q |
| User ID | App Functionality | Ha | Yo'q |
| Name | App Functionality | Ha | Yo'q |

"Do you or your third-party partners track users?" → **No**

### 3.4. Skrinshotlar — MAJBURIY

Kamida **6.9" iPhone** (1320×2868 yoki 1290×2796) uchun 3–10 ta skrinshot.

> ⚠️ **Simulyatorda skrinshot ololmaysiz.** Google ML Kit pod'lari Apple Silicon Mac'dagi
> iOS simulyatorini (arm64) qo'llab-quvvatlamaydi — build paytida shu ogohlantirish chiqadi.
> Skrinshotlarni **haqiqiy iPhone**'da oling: iPhone 16/17 Pro Max yoki shunga o'xshash
> katta ekranli qurilma (Power + Volume Up).
>
> Agar shunday qurilma bo'lmasa, kichikroq iPhone'da olib, rasmlarni 1290×2796 o'lchamiga
> kengaytirish mumkin, lekin Apple cho'zilgan skrinshotlarni yoqtirmaydi — imkon qadar
> to'g'ri qurilmada oling.

Tavsiya etiladigan ekranlar: login, asosiy sahifa (davomat statistikasi), yuz skanerlash, davomat tarixi.

> ⚠️ Yuz skanerlash ekrani skrinshotida **haqiqiy xodim yuzi bo'lmasin** — demo/rozilik olingan surat ishlating.

### 3.5. Boshqa metadata

- **Description** (o'zbek/rus tilida): ilova nima qilishini aniq yozing
- **Keywords**: davomat, HR, xodim, ish vaqti, yuz
- **Support URL**: `https://visionhr.uz` (ishlaydigan sahifa bo'lishi shart)
- **Category**: Business
- **Age Rating**: 4+
- **Content Rights**: uchinchi tomon kontenti yo'q

---

## 4. Rad etilish ehtimoli yuqori bo'lgan nuqtalar

| Xavf | Guideline | Qanday oldini olish |
|---|---|---|
| Reviewer login qila olmaydi | 2.1 | Ishlaydigan demo hisob + joylashuv ko'rsatmasi (3.1) |
| Joylashuv sababli davomat tugmasi ishlamaydi | 2.1 | Demo hisob uchun masofa tekshiruvini yumshating |
| Maxfiylik siyosati yo'q / yuz ma'lumoti tushuntirilmagan | 5.1.1 | Privacy Policy sahifasi (3.2) |
| Faqat bitta kompaniya uchun ilova deb baholanishi | 4.2 / 3.2.1 | Description'da Vision HR — ko'p kompaniyaga xizmat qiluvchi SaaS ekanini yozing |
| Timeout/tarmoq xatosida ilova "buzilgan" ko'rinishi | 2.1 | ✅ Tuzatildi — endi tushunarli xabar chiqadi |

**Hisob o'chirish (Guideline 5.1.1(v))**: ilova ichida ro'yxatdan o'tish yo'q, hisoblarni HR administrator yaratadi — shuning uchun ilova ichida hisob o'chirish talabi qo'llanilmaydi. Agar reviewer so'rasa, shu tushuntirishni bering.

---

## 5. Yuborishdan oldin oxirgi tekshiruv

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

- [ ] Haqiqiy iPhone'da sinaldi (kamera, GPS, login, davomat) — **simulyatorda ishlamaydi**, ML Kit arm64 simulyatorni qo'llab-quvvatlamaydi
- [ ] Sekin internetda ham davomat yozilishi tekshirildi
- [ ] `version:` pubspec.yaml'da oshirildi (hozir `1.0.2+7`; har yuklashda build raqami oshishi shart)
- [ ] Demo hisob ishlayotgani tekshirildi
- [ ] Privacy Policy sahifasi ochilyapti
- [ ] Skrinshotlar tayyor

Ko'rib chiqish odatda **24–48 soat** davom etadi.
