cat > ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

[ -f "$HOME/.kapak_ayarlari.conf" ] && source "$HOME/.kapak_ayarlari.conf"

ISLENENLER_LISTESI="$HOME/.islenenler.txt"
touch "$ISLENENLER_LISTESI"

# Sabit prefix
PREFIX="〖ذال فیلم تقدیم میکندょ〗"

# Renkler
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; RESET='\033[0m'

_kaydet_ayarlar() {
    echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\"" > "$HOME/.kapak_ayarlari.conf"
    echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\"" >> "$HOME/.kapak_ayarlari.conf"
}

_zaten_islendi_mi() {
    local aranan="$1"
    while IFS= read -r satir; do
        [ "$satir" = "$aranan" ] && return 0
    done < "$ISLENENLER_LISTESI"
    return 1
}

_ilerleme_goster() {
    local mevcut=$1
    local toplam=$2
    local yuzde=$(( mevcut * 100 / toplam ))
    local dolu=$(( yuzde / 5 ))
    local bos=$(( 20 - dolu ))
    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++));  do bar+="░"; done
    printf "\r  [%s] %3d%%  (%d/%d)" "$bar" "$yuzde" "$mevcut" "$toplam"
}

# ─────────────────────────────────────────
# DOSYA YENİDEN ADLANDIRMA MODÜLÜ
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
        echo -e "${YELLOW}5) Tüm müzikler${RESET}"
        echo -e "${YELLOW}6) Özel dizin belirt${RESET}"
        echo -e "${YELLOW}0) Ana Menüye Dön${RESET}"
        read -p "Seçiminiz [0-6]: " choice

        case "$choice" in
            1) DIRS=("/storage/emulated/0/VidMate/download"); MODE_TYPE="video" ;;
            2) DIRS=("/storage/emulated/0/snaptube/download/SnapTube Video"); MODE_TYPE="video" ;;
            3) DIRS=("/storage/emulated/0/VidMate/download" "/storage/emulated/0/snaptube/download/SnapTube Video"); MODE_TYPE="video" ;;
            4) DIRS=("/storage/emulated/0/Android/media/org.telegram.messenger/Telegram/Telegram Video"); MODE_TYPE="video" ;;
            5) MODE_TYPE="music" ;;
            6)
               read -p "Özel dizin yolunu girin: " custom_dir
               DIRS=("$custom_dir")
               MODE_TYPE="video"
               ;;
            0) ana_menu; return ;;
            *) echo -e "${RED}Geçersiz seçim!${RESET}"; sleep 1; continue ;;
        esac

        echo -e "\n${CYAN}--- İşlem Modu Seçimi ---${RESET}"
        echo -e "${YELLOW}1) Prefix ekle${RESET}"
        echo -e "${YELLOW}2) Metin kaldır${RESET}"
        echo -e "${YELLOW}0) Ana Menü${RESET}"
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
            echo -e "${GREEN}Kaldırılacak Metin: '$text_to_remove'${RESET}"
        fi

        processed=0; skipped=0; failed=0
        LOG_FILE="$HOME/process_log.txt"
        echo "Başlatma: $(date)" > "$LOG_FILE"

        process_file(){
            local f="$1"; local base="$(basename "$f")"
            case "$base" in *.nomedia|*.txt|*.json)
                echo -e "${BLUE}→ Atlandı (özel dosya):${RESET} $base"
                ((skipped++)); echo "SKIP-ÖZEL: $base" >>"$LOG_FILE"; return ;;
            esac
            if [[ "$MODE_OP" == "add" ]]; then
                if [[ "$base" == "$PREFIX"* ]]; then
                    echo -e "${BLUE}→ Atlandı (zaten prefix):${RESET} $base"
                    ((skipped++)); echo "SKIP-PREF: $base" >>"$LOG_FILE"; return
                fi
                local new="$PREFIX$base"
                if mv -- "$f" "$(dirname "$f")/$new"; then
                    echo -e "${GREEN}✓ Eklendi:${RESET} $base → $new"
                    ((processed++)); echo "ADD: $base → $new" >>"$LOG_FILE"
                else
                    echo -e "${RED}✗ Hata:${RESET} $base"
                    ((failed++)); echo "ERR-ADD: $base" >>"$LOG_FILE"
                fi
            else
                if [[ "$base" == *"$text_to_remove"* ]]; then
                    local cleaned="${base//$text_to_remove/}"
                    local target="$(dirname "$f")/$cleaned"
                    if [[ -z "$cleaned" || "$target" == "$f" ]]; then
                        echo -e "${BLUE}→ Atlandı (geçersiz hedef):${RESET} $base"
                        ((skipped++)); echo "SKIP-REM: $base" >>"$LOG_FILE"; return
                    fi
                    if mv -- "$f" "$target"; then
                        echo -e "${GREEN}✓ Kaldırıldı:${RESET} $base → $cleaned"
                        ((processed++)); echo "REM: $base → $cleaned" >>"$LOG_FILE"
                    else
                        echo -e "${RED}✗ Hata:${RESET} $base"
                        ((failed++)); echo "ERR-REM: $base" >>"$LOG_FILE"
                    fi
                else
                    echo -e "${BLUE}→ Atlandı (metin yok):${RESET} $base"
                    ((skipped++)); echo "SKIP-REM: $base" >>"$LOG_FILE"
                fi
            fi
        }

        if [[ "$MODE_TYPE" == "video" ]]; then
            for d in "${DIRS[@]}"; do
                echo -e "\n${CYAN}--- Tarama: $d ---${RESET}"
                while IFS= read -r -d '' file; do
                    process_file "$file"
                done < <(find "$d" -maxdepth 1 -type f -print0)
            done
        else
            echo -e "\n${CYAN}--- Tüm müzikler ---${RESET}"
            while IFS= read -r -d '' file; do
                process_file "$file"
            done < <(find /storage/emulated/0 \
                -path "/storage/emulated/0/Android/data" -prune -o \
                -path "/storage/emulated/0/Android/obb" -prune -o \
                -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.m4a" \
                -o -iname "*.flac" -o -iname "*.aac" -o -iname "*.ogg" \) -print0)
        fi

        echo -e "\n${MAGENTA}========================================${RESET}"
        echo -e "${GREEN}✓ İşlenen:  $processed${RESET}"
        echo -e "${BLUE}→ Atlanan:  $skipped${RESET}"
        echo -e "${RED}✗ Hatalı:   $failed${RESET}"
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
    echo "  Resim  : ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
    echo "  Prefix : $PREFIX"
    echo "-----------------------------------------"
    echo "  1 - Videoların Kapağını Güncelle"
    echo "      (Kapak değişir + prefix otomatik eklenir)"
    echo "  2 - Hafızayı Sil (Tüm videoları tekrar işle)"
    echo "  3 - Resim Ayarını Değiştir"
    echo "  4 - Dosya Yeniden Adlandır"
    echo "  5 - Çıkış"
    echo "========================================="
    read -p "Seçiminiz: " secim

    case $secim in
        1)
            if [ -z "$VARSAYILAN_RESIM" ]; then
                echo "  HATA: Önce resim ayarını yapın! (Seçenek 3)"
                sleep 2; ana_menu; return
            fi

            if [ ! -f "$VARSAYILAN_RESIM" ]; then
                echo "  HATA: Resim bulunamadı: $VARSAYILAN_RESIM"
                sleep 2; ana_menu; return
            fi

            echo ""
            echo "  Son kullanılan klasör: ${VARSAYILAN_KLASOR:-'Yok'}"
            read -p "  Video Klasörü Tam Yolu: " girilen_klasor

            if [ -z "$girilen_klasor" ]; then
                echo "  İptal edildi."
                sleep 1; ana_menu; return
            fi

            if [ ! -d "$girilen_klasor" ]; then
                echo "  HATA: Klasör bulunamadı: $girilen_klasor"
                sleep 2; ana_menu; return
            fi

            VARSAYILAN_KLASOR="$girilen_klasor"
            _kaydet_ayarlar

            TEMP_LIST="$HOME/.video_listesi_tmp.txt"
            find "$VARSAYILAN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST"

            toplam=$(wc -l < "$TEMP_LIST")

            if [ "$toplam" -eq 0 ]; then
                echo "  Bu klasörde hiç video bulunamadı!"
                rm -f "$TEMP_LIST"
                sleep 2; ana_menu; return
            fi

            zaten=0
            while IFS= read -r video; do
                isim=$(basename "$video")
                _zaten_islendi_mi "$isim" && zaten=$((zaten + 1))
            done < "$TEMP_LIST"

            islencek=$((toplam - zaten))

            clear
            echo "========================================="
            echo "           İŞLEM BAŞLIYOR               "
            echo "========================================="
            echo "  Toplam video  : $toplam"
            echo "  Zaten yapılmış: $zaten"
            echo "  İşlenecek     : $islencek"
            echo "-----------------------------------------"

            if [ "$islencek" -eq 0 ]; then
                echo "  Tüm videolar zaten işlenmiş!"
                rm -f "$TEMP_LIST"
                read -p "  Enter'a bas..."
                ana_menu; return
            fi

            islem_sayisi=0
            hata_sayisi=0

            while IFS= read -r video; do
                isim=$(basename "$video")
                klasor=$(dirname "$video")

                _zaten_islendi_mi "$isim" && continue

                islem_sayisi=$((islem_sayisi + 1))
                _ilerleme_goster "$islem_sayisi" "$islencek"

                temp_dosya="$klasor/temp_$$_$islem_sayisi.mp4"

                ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" \
                    -map 0 -map 1 -c copy \
                    -disposition:v:1 attached_pic \
                    "$temp_dosya" -y -loglevel quiet 2>/dev/null

                if [ $? -eq 0 ]; then
                    # Kapak değişti, şimdi prefix ekle (zaten prefix yoksa)
                    uzanti="${isim##*.}"
                    isim_base="${isim%.*}"
                    if [[ "$isim" == "$PREFIX"* ]]; then
                        # Zaten prefix var, sadece taşı
                        mv "$temp_dosya" "$video"
                        yeni_isim="$isim"
                    else
                        # Prefix ekle ve yeniden adlandır
                        yeni_isim="${PREFIX}${isim}"
                        mv "$temp_dosya" "$klasor/$yeni_isim"
                        rm -f "$video"
                    fi
                    echo "$yeni_isim" >> "$ISLENENLER_LISTESI"
                else
                    rm -f "$temp_dosya"
                    hata_sayisi=$((hata_sayisi + 1))
                fi

            done < "$TEMP_LIST"

            rm -f "$TEMP_LIST"

            echo ""
            echo "-----------------------------------------"
            echo "  ✓ Tamamlandı!"
            echo "  İşlenen : $islem_sayisi video"
            echo "  Hata    : $hata_sayisi video"
            echo "  Atlanan : $zaten video (zaten yapılmıştı)"
            echo "========================================="
            read -p "  Enter'a bas..."
            ana_menu
            ;;

        2)
            read -p "  Emin misiniz? (e/h): " onay
            if [ "$onay" = "e" ] || [ "$onay" = "E" ]; then
                rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"
                echo "  Hafıza silindi."
            else
                echo "  İptal edildi."
            fi
            sleep 1; ana_menu
            ;;

        3)
            echo ""
            echo "  Mevcut resim: ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
            read -p "  Yeni Resim Tam Yolu (boş bırakırsan değişmez): " yeni_r
            if [ ! -z "$yeni_r" ]; then
                if [ -f "$yeni_r" ]; then
                    VARSAYILAN_RESIM="$yeni_r"
                    _kaydet_ayarlar
                    echo "  Resim güncellendi."
                else
                    echo "  HATA: Dosya bulunamadı."
                fi
            else
                echo "  Değişiklik yapılmadı."
            fi
            sleep 1; ana_menu
            ;;

        4)
            adlandirma_menu
            ;;

        5)
            echo "  Çıkılıyor..."
            exit 0
            ;;

        *)
            echo "  Geçersiz seçim!"
            sleep 1; ana_menu
            ;;
    esac
}

ana_menu
EOF
chmod +x ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
echo "Güncellendi!"
