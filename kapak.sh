#!/data/data/com.termux/files/usr/bin/bash

# --- AYAR DOSYASI (Ayarların kalıcı olması için) ---
CONFIG_FILE="$HOME/.kapak_ayarlari.conf"

# Ayarları yükle veya varsayılan oluştur
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    VARSAYILAN_RESIM="/sdcard/Pictures/kapak.jpg"
    VARSAYILAN_KLASOR="/sdcard/Download/TurboShared"
fi

ana_menu() {
    clear
    echo -e "\033[1;34m===============================================\033[0m"
    echo -e "\033[1;32m       VİDEO KAPAK DEĞİŞTİRİCİ - PRO V2       \033[0m"
    echo -e "\033[1;34m===============================================\033[0m"
    echo "1 - Tüm Videoların Kapağını Değiştir"
    echo "2 - Mevcut Ayarları Gör"
    echo "3 - Ayarları Düzenle (Klasör ve Resim Yolu)"
    echo "4 - Çıkış"
    echo -e "\033[1;34m===============================================\033[0m"
    read -p "Seçiminiz [1-4]: " secim

    case $secim in
        1) kapak_islemine_basla ;;
        2) ayarlari_goster ;;
        3) ayarlari_duzenle ;;
        4) echo "Görüşürüz!"; exit 0 ;;
        *) echo "Geçersiz!"; sleep 1; ana_menu ;;
    esac
}

ayarlari_goster() {
    clear
    echo "--- MEVCUT AYARLAR ---"
    echo "Hedef Klasör: $VARSAYILAN_KLASOR"
    echo "Kapak Resmi : $VARSAYILAN_RESIM"
    read -p "Ana menü için Enter..."
    ana_menu
}

ayarlari_duzenle() {
    clear
    echo "--- AYARLARI GÜNCELLE ---"
    read -p "Yeni Video Klasör Yolunu Yazın (Enter ile geç): " yeni_klasor
    read -p "Yeni Kapak Resim Yolunu Yazın (Enter ile geç): " yeni_resim

    [ ! -z "$yeni_klasor" ] && VARSAYILAN_KLASOR="$yeni_klasor"
    [ ! -z "$yeni_resim" ] && VARSAYILAN_RESIM="$yeni_resim"

    # Ayarları kaydet
    echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\"" > "$CONFIG_FILE"
    echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\"" >> "$CONFIG_FILE"
    
    echo "Ayarlar kaydedildi!"
    sleep 1
    ana_menu
}

kapak_islemine_basla() {
    if [ ! -d "$VARSAYILAN_KLASOR" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
        echo "Hata: Yollar hatalı! Önce ayarları kontrol edin."
        read -p "Enter..."
        ana_menu
    fi

    CIKTI_DIR="$VARSAYILAN_KLASOR/Kapakli_Videolar"
    mkdir -p "$CIKTI_DIR"

    cd "$VARSAYILAN_KLASOR"
    for video in *.{mp4,mkv}; do
        [ -e "$video" ] || continue
        echo "İşleniyor: $video"
        ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "$CIKTI_DIR/$video" -y -loglevel quiet
    done
    
    echo "İşlem bitti! Videolar '$CIKTI_DIR' klasöründe."
    read -p "Ana menü için Enter..."
    ana_menu
}

ana_menu
