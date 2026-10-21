# iOS ve TestFlight

iOS derlemesi GitHub Actions'ta Mac'siz yapılır (Küpler'deki hattın aynısı):
`.github/workflows/ios.yml` derler, imzalar, TestFlight'a yükler ve derlemeyi
herkese açık test grubuna ekler. İmza sertifikasını ve profili
`ios/ci_signing.py` App Store Connect API'siyle kendisi oluşturur; Mac,
Xcode ya da elle sertifika gerekmez.

- Paket kimliği: `com.erkanoz.golge`
- Takım: `8PYZ45XP74`
- Mağaza metinleri: `ios/metadata/store.json`
- Gizlilik sayfası: `docs/GIZLILIK.md`

## Bir kez yapılacaklar

1. **App Store Connect'te uygulama kaydı:** Uygulamalar → **+** → Yeni
   Uygulama. Platform iOS, ad **Gölge Oyunu**, birincil dil Türkçe, paket
   kimliği **com.erkanoz.golge**, SKU `golge`.
   Paket kimliği listede yoksa önce Apple Developer → Certificates, IDs &
   Profiles → Identifiers → **+** → App IDs → App ile `com.erkanoz.golge`
   kaydedilir (ilk iş akışı çalışması da kendisi kaydeder; ama uygulama kaydı
   olmadan yükleme yapılamaz).

2. **GitHub sırları** (Küpler'de kullanılan aynı API anahtarı olabilir):
   depo → Settings → Secrets and variables → Actions → New repository secret

   | Sır | Değer |
   |---|---|
   | `ASC_KEY_ID` | API anahtarının kimliği |
   | `ASC_ISSUER_ID` | Issuer ID |
   | `ASC_PRIVATE_KEY` | `.p8` dosyasının içeriği (BEGIN/END satırlarıyla) |
   | `ASC_CONTACT_EMAIL` | TestFlight inceleme iletişim e-postası |
   | `ASC_CONTACT_PHONE` | Telefon (`+90 5xx xxx xx xx`) |

   Komut satırından da girilebilir:

   ```
   gh secret set ASC_KEY_ID --repo 07erkanoz/golgeoyunu
   gh secret set ASC_ISSUER_ID --repo 07erkanoz/golgeoyunu
   gh secret set ASC_PRIVATE_KEY --repo 07erkanoz/golgeoyunu < AuthKey_XXXX.p8
   gh secret set ASC_CONTACT_EMAIL --repo 07erkanoz/golgeoyunu
   gh secret set ASC_CONTACT_PHONE --repo 07erkanoz/golgeoyunu
   ```

## Yeni TestFlight derlemesi

`ios/testflight.txt` içindeki sayıyı bir artırıp main'e gönder, ya da
Actions → **iOS TestFlight** → Run workflow. Apple ilk derlemeyi beta
incelemesine alır (genellikle bir gün); onaylanınca herkese açık test
bağlantısı iş akışının özetinde görünür.

## Bilinmesi gerekenler

- Apple bir takımda yalnızca birkaç dağıtım sertifikasına izin verir.
  Küpler'in hattı da bir sertifika tutuyor; sınır doluysa bu hat yalnızca
  kendi oluşturduklarını iptal eder, Küpler'inkine dokunmaz ve açık bir
  hatayla durur. O durumda Apple Developer → Certificates'ten kullanılmayan
  eski bir dağıtım sertifikası silinmeli.
- Sertifika bir derlemeden sonra iptal edilmez: iptal, o sertifikayla
  imzalanmış derlemeleri geçersiz kılar.
