cat > ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

[ -f "$HOME/.kapak_ayarlari.conf" ] && source "$HOME/.kapak_ayarlari.conf"

# ─────────────────────────────────────────
# KİLİT KONTROLÜ
# Aynı anda 2. kopya çalışmasını engeller.
# ─────────────────────────────────────────
KILIT_DOSYA="$HOME/.kapak_script.lock"

if [ -f "$KILIT_DOSYA" ]; then
    eski_pid=$(cat "$KILIT_DOSYA" 2>/dev/null)
    if [ -n "$eski_pid" ] && kill -0 "$eski_pid" 2>/dev/null; then
        echo ""
        echo "========================================="
        echo "  ⚠️  UYARI: Script zaten çalışıyor!"
        echo "========================================="
        echo "  Aynı anda 2 kopya çalıştırmak dosyaların"
        echo "  birbirini bozmasına yol açar."
        echo ""
        echo "  Diğer terminal/oturumdaki script'i"
        echo "  kapatıp tekrar dene."
        echo "========================================="
        exit 1
    fi
fi

echo $$ > "$KILIT_DOSYA"

# Script ne şekilde olursa olsun kapanırken kilidi sil
trap 'rm -f "$KILIT_DOSYA"' EXIT

ISLENENLER_LISTESI="$HOME/.islenenler.txt"
touch "$ISLENENLER_LISTESI"

PREFIX="〖ذال فیلم تقدیم میکندょ〗"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; RESET='\033[0m'

# ─────────────────────────────────────────
# AYARLARI KAYDET
# ─────────────────────────────────────────
_kaydet_ayarlar() {
    cat > "$HOME/.kapak_ayarlari.conf" << CONF
VARSAYILAN_RESIM="$VARSAYILAN_RESIM"
SON_KAPAK_KLASOR="$SON_KAPAK_KLASOR"
CONF
}

_zaten_islendi_mi() {
    local aranan="$1"
    while IFS= read -r satir; do
        [ "$satir" = "$aranan" ] && return 0
    done < "$ISLENENLER_LISTESI"
    return 1
}

_ilerleme_goster() {
    local mevcut=$1 toplam=$2
    local yuzde=$(( mevcut * 100 / toplam ))
    local dolu=$(( yuzde / 5 )) bos=$(( 20 - yuzde / 5 ))
    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++));  do bar+="░"; done
    printf "\r  [%s] %3d%%  (%d/%d)" "$bar" "$yuzde" "$mevcut" "$toplam"
}

# ─────────────────────────────────────────
# KAPAK RESMİNİ UYUMLU JPG'E ÇEVİR
# ─────────────────────────────────────────
_kapak_jpg_hazirla() {
    KAPAK_JPG=""
    [ -z "$VARSAYILAN_RESIM" ] && return 1
    [ ! -f "$VARSAYILAN_RESIM" ] && return 1

    local hedef="$HOME/.kapak_cache.jpg"

    if [ -f "$hedef" ] && [ -f "$HOME/.kapak_cache_src.txt" ]; then
        local onceki_kaynak
        onceki_kaynak=$(cat "$HOME/.kapak_cache_src.txt")
        if [ "$onceki_kaynak" = "$VARSAYILAN_RESIM" ]; then
            KAPAK_JPG="$hedef"
            return 0
        fi
    fi

    ffmpeg -i "$VARSAYILAN_RESIM" -vf "scale='min(1280,iw)':-2" \
        -frames:v 1 "$hedef" -y -loglevel quiet 2>/dev/null

    if [ -f "$hedef" ]; then
        echo "$VARSAYILAN_RESIM" > "$HOME/.kapak_cache_src.txt"
        KAPAK_JPG="$hedef"
        return 0
    fi

    return 1
}

# ─────────────────────────────────────────
# HATA LOGUNA YAZ
# ─────────────────────────────────────────
HATA_LOG="$HOME/hata_log.txt"
_hata_logla() {
    local mod="$1" dosya="$2" mesaj="$3"
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$mod] $dosya"
        echo "  → $mesaj"
        echo "---"
    } >> "$HATA_LOG"
}

# ─────────────────────────────────────────
# KAYNAK KLASÖR SEÇİM YARDIMCISI
# ─────────────────────────────────────────
_kaynak_sec() {
    local baslik="$1"
    local son_deger="$2"

    echo -e "\n${YELLOW}[ $baslik ]${RESET}"
    echo -e "  1) VidMate indirmeleri"
    echo -e "  2) SnapTube indirmeleri"
    echo -e "  3) VidMate & SnapTube birlikte"
    echo -e "  4) Telegram videoları"
    echo -e "  5) Özel dizin belirt"
    if [ -n "$son_deger" ]; then
        echo -e "  ${GREEN}[Enter] Son kullanılan: $son_deger${RESET}"
    fi
    echo -e "  0) Ana Menüye Dön"
    read -p "Seçiminiz [0-5]: " _src

    case "$_src" in
        "")
            if [ -n "$son_deger" ]; then
                SECILEN_KLASOR="$son_deger"
            else
                echo -e "${RED}Kayıtlı klasör yok!${RESET}"; SECILEN_KLASOR=""; return 1
            fi
            ;;
        1) SECILEN_KLASOR="/storage/emulated/0/VidMate/download" ;;
        2) SECILEN_KLASOR="/storage/emulated/0/snaptube/download/SnapTube Video" ;;
        3) SECILEN_KLASOR="VidMate+SnapTube" ;;
        4) SECILEN_KLASOR="/storage/emulated/0/Android/media/org.telegram.messenger/Telegram/Telegram Video" ;;
        5)
           read -p "Dizin yolunu girin: " _custom
           if [ -z "$_custom" ] || [ ! -d "$_custom" ]; then
               echo -e "${RED}Geçersiz dizin!${RESET}"; SECILEN_KLASOR=""; return 1
           fi
           SECILEN_KLASOR="$_custom"
           ;;
        0) ana_menu; return 2 ;;
        *) echo -e "${RED}Geçersiz seçim!${RESET}"; SECILEN_KLASOR=""; return 1 ;;
    esac
    return 0
}

# ─────────────────────────────────────────
# 1) KAPAK DEĞİŞTİRME
# ─────────────────────────────────────────
kapak_degistir_isle() {
    if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
        echo -e "  ${RED}HATA: Önce resim ayarını yapın! (Seçenek 3)${RESET}"
        sleep 2; ana_menu; return
    fi

    clear
    echo -e "${CYAN}=========================================${RESET}"
    echo -e "${CYAN}      Kapak Değiştirme - Klasör Seç${RESET}"
    echo -e "${CYAN}=========================================${RESET}"

    _kaynak_sec "Video Klasörü Seçin" "$SON_KAPAK_KLASOR"
    local ret=$?
    [ $ret -eq 2 ] && return
    [ $ret -eq 1 ] && { sleep 1; kapak_degistir_isle; return; }
    [ -z "$SECILEN_KLASOR" ] && { sleep 1; kapak_degistir_isle; return; }

    if [[ "$SECILEN_KLASOR" == "VidMate+SnapTube" ]]; then
        echo -e "${RED}Bu mod için tek bir klasör seçin.${RESET}"; sleep 2; kapak_degistir_isle; return
    fi

    if [ ! -d "$SECILEN_KLASOR" ]; then
        echo -e "  ${RED}HATA: Klasör bulunamadı: $SECILEN_KLASOR${RESET}"
        sleep 2; kapak_degistir_isle; return
    fi

    SON_KAPAK_KLASOR="$SECILEN_KLASOR"
    _kaydet_ayarlar

    _kapak_jpg_hazirla
    if [ -z "$KAPAK_JPG" ]; then
        echo -e "  ${RED}HATA: Kapak resmi hazırlanamadı (dosya bozuk olabilir).${RESET}"
        sleep 2; ana_menu; return
    fi

    TEMP_LIST="$HOME/.video_listesi_tmp.txt"
    find "$SECILEN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST"
    toplam=$(wc -l < "$TEMP_LIST")

    if [ "$toplam" -eq 0 ]; then
        echo -e "  ${RED}Bu klasörde hiç video bulunamadı!${RESET}"
        rm -f "$TEMP_LIST"; sleep 2; ana_menu; return
    fi

    zaten=0
    while IFS= read -r video; do
        _zaten_islendi_mi "$(basename "$video")" && zaten=$((zaten + 1))
    done < "$TEMP_LIST"
    islencek=$((toplam - zaten))

    clear
    echo "========================================="
    echo "           İŞLEM BAŞLIYOR               "
    echo "========================================="
    echo "  Klasör       : $SECILEN_KLASOR"
    echo "  Toplam video : $toplam"
    echo "  Zaten yapıldı: $zaten"
    echo "  İşlenecek    : $islencek"
    echo "-----------------------------------------"

    if [ "$islencek" -eq 0 ]; then
        echo "  Tüm videolar zaten işlenmiş!"
        rm -f "$TEMP_LIST"; read -p "  Enter'a bas..."; ana_menu; return
    fi

    islem_sayisi=0; hata_sayisi=0; kapaksiz_sayisi=0
    > "$HATA_LOG"

    while IFS= read -r video; do
        isim=$(basename "$video")
        klasor=$(dirname "$video")
        _zaten_islendi_mi "$isim" && continue

        islem_sayisi=$((islem_sayisi + 1))
        _ilerleme_goster "$islem_sayisi" "$islencek"

        temp_dosya="$klasor/.tmp_kapak_$$_${islem_sayisi}.mp4"
        ffmpeg_err=$(mktemp)

        ffmpeg -i "$video" -i "$KAPAK_JPG" \
            -map 0 -map 1 -c copy -c:v:1 mjpeg \
            -disposition:v:1 attached_pic \
            "$temp_dosya" -y -loglevel error 2> "$ffmpeg_err"

        basarili=$?

        if [ $basarili -ne 0 ]; then
            rm -f "$temp_dosya"
            ffmpeg -i "$video" -map 0 -c copy \
                "$temp_dosya" -y -loglevel error 2> "$ffmpeg_err"
            basarili=$?
            if [ $basarili -eq 0 ]; then
                kapaksiz_sayisi=$((kapaksiz_sayisi + 1))
                _hata_logla "KAPAK" "$isim" "Kapak eklenemedi, kapaksız işlendi: $(tail -1 "$ffmpeg_err")"
            fi
        fi

        if [ $basarili -eq 0 ]; then
            if [[ "$isim" == "$PREFIX"* ]]; then
                mv "$temp_dosya" "$video"
                yeni_isim="$isim"
            else
                yeni_isim="${PREFIX}${isim}"
                mv "$temp_dosya" "$klasor/$yeni_isim"
                rm -f "$video"
            fi
            echo "$yeni_isim" >> "$ISLENENLER_LISTESI"
        else
            rm -f "$temp_dosya"
            hata_sayisi=$((hata_sayisi + 1))
            _hata_logla "KAPAK" "$isim" "Tamamen başarısız: $(tail -1 "$ffmpeg_err")"
        fi

        rm -f "$ffmpeg_err"
    done < "$TEMP_LIST"

    rm -f "$TEMP_LIST"
    echo ""
    echo "-----------------------------------------"
    echo "  ✓ Tamamlandı!"
    echo "  İşlenen        : $islem_sayisi video"
    echo "  Kapaksız işlendi: $kapaksiz_sayisi video"
    echo "  Hata           : $hata_sayisi video"
    echo "  Atlanan        : $zaten video (zaten yapılmıştı)"
    if [ "$hata_sayisi" -gt 0 ] || [ "$kapaksiz_sayisi" -gt 0 ]; then
        echo "  Detaylar       : $HATA_LOG"
    fi
    echo "========================================="
    read -p "  Enter'a bas..."
    ana_menu
}

# ─────────────────────────────────────────
# 4) DOSYA YENİDEN ADLANDIRMA
# ─────────────────────────────────────────
adlandirma_menu() {
    while true; do
        clear
        echo -e "\n${CYAN}========================================${RESET}"
        echo -e "${CYAN}       Klasör Seçimi Menüsü${RESET}"
        echo -e "${CYAN}========================================${RESET}"
        echo -e "${YELLOW}1) VidMate indirilenleri işle${RESET}"
        echo -e "${YELLOW}2) SnapTube indirilenleri işle${RESET}"
        echo -e "${YELLOW}3) VidMate & SnapTube birlikte${RESET}"
        echo -e "${YELLOW}4) Telegram videolarını işle${RESET}"
        echo -e "${YELLOW}5) Özel dizin belirt${RESET}"
        echo -e "${YELLOW}0) Ana Menüye Dön${RESET}"
        read -p "Seçiminiz [0-5]: " choice

        case "$choice" in
            1) DIRS=("/storage/emulated/0/VidMate/download") ;;
            2) DIRS=("/storage/emulated/0/snaptube/download/SnapTube Video") ;;
            3) DIRS=("/storage/emulated/0/VidMate/download" "/storage/emulated/0/snaptube/download/SnapTube Video") ;;
            4) DIRS=("/storage/emulated/0/Android/media/org.telegram.messenger/Telegram/Telegram Video") ;;
            5) read -p "Özel dizin yolunu girin: " custom_dir; DIRS=("$custom_dir") ;;
            0) ana_menu; return ;;
            *) echo -e "${RED}Geçersiz seçim!${RESET}"; sleep 1; continue ;;
        esac

        echo -e "\n${CYAN}--- İşlem Modu ---${RESET}"
        echo -e "${YELLOW}1) Prefix ekle  2) Metin kaldır  0) Ana Menü${RESET}"
        read -p "Seçiminiz [0-2]: " op_mode
        case "$op_mode" in
            1) MODE_OP="add" ;;
            2) MODE_OP="remove" ;;
            0) ana_menu; return ;;
            *) echo -e "${RED}Geçersiz seçim!${RESET}"; sleep 1; continue ;;
        esac

        if [[ "$MODE_OP" == "add" ]]; then
            echo -e "${GREEN}Prefix: $PREFIX${RESET}"
        else
            read -p "Kaldırılacak metni girin: " text_to_remove
            [[ -z "$text_to_remove" ]] && { echo -e "${RED}Hiç metin girilmedi!${RESET}"; sleep 1; continue; }
        fi

        processed=0; skipped=0; failed=0
        LOG_FILE="$HOME/process_log.txt"
        echo "Başlatma: $(date)" > "$LOG_FILE"

        process_file(){
            local f="$1" base="$(basename "$1")"
            case "$base" in *.nomedia|*.txt|*.json)
                ((skipped++)); return ;; esac
            if [[ "$MODE_OP" == "add" ]]; then
                [[ "$base" == "$PREFIX"* ]] && { ((skipped++)); return; }
                mv -- "$f" "$(dirname "$f")/$PREFIX$base" && ((processed++)) || ((failed++))
            else
                [[ "$base" != *"$text_to_remove"* ]] && { ((skipped++)); return; }
                local cleaned="${base//$text_to_remove/}"
                local target="$(dirname "$f")/$cleaned"
                [[ -z "$cleaned" || "$target" == "$f" ]] && { ((skipped++)); return; }
                mv -- "$f" "$target" && ((processed++)) || ((failed++))
            fi
        }

        for d in "${DIRS[@]}"; do
            echo -e "\n${CYAN}--- Tarama: $d ---${RESET}"
            while IFS= read -r -d '' file; do process_file "$file"; done \
                < <(find "$d" -maxdepth 1 -type f -print0)
        done

        echo -e "\n${MAGENTA}========================================${RESET}"
        echo -e "${GREEN}✓ İşlenen: $processed  ${BLUE}→ Atlanan: $skipped  ${RED}✗ Hatalı: $failed${RESET}"
        echo -e "${MAGENTA}========================================${RESET}"
        read -p $'\nAna menüye dönmek için Enter...' _
        ana_menu; return
    done
}

# ─────────────────────────────────────────
# ANA MENÜ
# ─────────────────────────────────────────
ana_menu() {
    clear
    echo "========================================="
    echo "      KAPAK DEĞİŞTİRİCİ (HAFIZALI)      "
    echo "========================================="
    echo "  Resim      : ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
    echo "  Son Kapak  : ${SON_KAPAK_KLASOR:-'Henüz yok'}"
    echo "-----------------------------------------"
    echo "  1 - Video Kapağını Değiştir + Prefix Ekle"
    echo "  2 - Hafızayı Sil"
    echo "  3 - Resim Ayarını Değiştir"
    echo "  4 - Dosya Yeniden Adlandır"
    echo "  5 - Çıkış"
    echo "========================================="
    read -p "Seçiminiz: " secim

    case $secim in
        1) kapak_degistir_isle ;;
        2)
            read -p "  Emin misiniz? (e/h): " onay
            [[ "$onay" == "e" || "$onay" == "E" ]] && {
                rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"
                echo "  Hafıza silindi."
            } || echo "  İptal edildi."
            sleep 1; ana_menu
            ;;
        3)
            echo ""
            echo "  Mevcut resim: ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
            read -p "  Yeni Resim Tam Yolu (boş = değişmez): " yeni_r
            if [ -n "$yeni_r" ]; then
                [ -f "$yeni_r" ] && { VARSAYILAN_RESIM="$yeni_r"; _kaydet_ayarlar; echo "  Resim güncellendi."; } \
                                 || echo "  HATA: Dosya bulunamadı."
            else
                echo "  Değişiklik yapılmadı."
            fi
            sleep 1; ana_menu
            ;;
        4) adlandirma_menu ;;
        5) echo "  Çıkılıyor..."; exit 0 ;;
        *) echo "  Geçersiz seçim!"; sleep 1; ana_menu ;;
    esac
}

ana_menu
EOF
chmod +x ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
echo "Güncellendi!"

