# 🎬 Video Kapak Resmi Değiştirici (Menülü & Hızlı)

Bu script, videolarınızın kalitesini ve orijinal kodunu (render etmeden) kesinlikle bozmadan, sadece birkaç saniye içinde klasördeki tüm videolara sabit bir kapak fotoğrafı (thumbnail) gömer. 

İşlemi ışık hızında bitirmek için `FFmpeg`'in `-c copy` özelliğini kullanır.

---

## 🛠️ Kurulum ve Gerekli Paketler

Scriptin Termux üzerinde sorunsuz çalışabilmesi için öncelikle gerekli paketlerin kurulması ve depolama izninin verilmesi gerekir.

Termux'u açın ve sırasıyla şu komutları çalıştırın:

```bash
# 1. Depolama iznini verin (Telefon hafızasına erişim için)
termux-setup-storage

# 2. Sistem paketlerini güncelleyin
pkg update && pkg upgrade -y

# 3. Gerekli araçları (FFmpeg) kurun
pkg install ffmpeg -y

# 1. Scripte çalıştırma izni verin
chmod +x kapak.sh

# 2. Scripti başlatın
./kapak.sh

